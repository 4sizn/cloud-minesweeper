"""Compare v1 and learned v2 on date-held-out, deduplicated SWIMSEG images."""
import csv
import hashlib
import json
import time
from pathlib import Path
import numpy as np
import onnxruntime as ort
from PIL import Image, ImageDraw
import torch
from train import ROOT, CloudNet, MobileCloudNet, load_data, metrics


def smooth(lo, hi, x):
    t = np.clip((x-lo)/(hi-lo), 0, 1)
    return t*t*(3-2*t)


def baseline(rgb, sky):
    r,g,b = (rgb.astype(np.float32)/255).transpose(2,0,1)
    light = np.maximum(r,np.maximum(g,b))
    sat = (light-np.minimum(r,np.minimum(g,b)))/np.maximum(.04,light)
    return smooth(.7,.94,r/np.maximum(.04,b))*smooth(.18,.55,light)*(1-smooth(.45,.85,sat))*smooth(.4,.8,sky)


def sky_mask(session, rgb):
    x = rgb.astype(np.float32)/max(1,int(rgb.max()))
    x = ((x - np.array([.406,.456,.485])) / np.array([.225,.224,.229])).transpose(2,0,1)[None].astype(np.float32)
    return session.run(None, {'image':x})[0][0,0]


def grid(x):
    return x.reshape(len(x),16,20,16,20).mean((2,4))


def component(mask):
    remaining = set(np.flatnonzero(mask)); best=set()
    while remaining:
        todo=[remaining.pop()]; found=set(todo)
        while todo:
            i=todo.pop(); y,x=divmod(i,16)
            for yy in range(max(0,y-1),min(16,y+2)):
                for xx in range(max(0,x-1),min(16,x+2)):
                    j=yy*16+xx
                    if j in remaining:
                        remaining.remove(j);found.add(j);todo.append(j)
        if len(found)>len(best):best=found
    out=np.zeros(256,dtype=bool)
    if len(best)<=256*.92:out[list(best)]=True
    return out.reshape(16,16)


def main():
    torch.set_num_threads(4)
    data, manifest=load_data(ROOT/'.local-data/clouds/swimseg-2')
    out=ROOT/'.local-data/clouds/training'
    model=CloudNet().eval()
    model.load_state_dict(torch.load(out/'best.pt',weights_only=True))
    wrapper=MobileCloudNet(model).eval()
    target=ROOT/'assets/models/cloud_swimseg_v1.onnx'
    torch.onnx.export(wrapper,torch.zeros(1,3,320,320),str(target),
                      input_names=['rgb'],output_names=['cloud'],opset_version=17,dynamo=False)
    opts=ort.SessionOptions();opts.intra_op_num_threads=2;opts.inter_op_num_threads=1
    sky=ort.InferenceSession(str(ROOT/'assets/models/sky_u2netp_v1.onnx'),opts)
    cloud=ort.InferenceSession(str(target),opts)
    summary={'counts':{k:len(v) for k,v in data.items()},'duplicates_removed':sum(r['split']=='duplicate' for r in manifest),
             'split_seed':20260921,'split_by':'capture date','threshold_selection':'validation grid IoU only',
             'cloud_model_sha256':hashlib.sha256(target.read_bytes()).hexdigest()}
    cases=[]; chosen=.5; start=time.monotonic()
    for split in ('val','test'):
        old=[];new=[];gt=[];skies=[];rgb_all=[]
        for n,(rgb,_,id) in enumerate(data[split]):
            sky_file=out/f'sky-{id}.npy'
            if sky_file.exists(): sm=np.load(sky_file)
            else: sm=sky_mask(sky,rgb);np.save(sky_file,sm)
            raw=rgb.astype(np.float32).transpose(2,0,1)[None]
            cm=cloud.run(None,{'rgb':raw})[0][0,0]
            # Cloud scores are gated by the existing sky model to reject buildings.
            old.append(baseline(rgb,sm));new.append(cm*smooth(.4,.8,sm));skies.append(sm)
            p=next((ROOT/'.local-data/clouds/swimseg-2').glob(f'*_labels/{id}.png'))
            gt.append(np.array(Image.open(p).convert('L').resize((320,320),Image.Resampling.NEAREST))>127)
            rgb_all.append(rgb)
            if n%50==0:print(split,n,'elapsed',round(time.monotonic()-start),flush=True)
        old,new,gt,skies=np.array(old),np.array(new),np.array(gt),np.array(skies)
        og,ng,gg=grid(old),grid(new),grid(gt.astype(float))>=.5
        if split=='val':
            candidates=[(float(t), metrics(ng,gg,float(t))['iou']) for t in np.arange(.3,.701,.025)]
            chosen=max(candidates,key=lambda x:x[1])[0]
            summary['threshold_validation']=candidates
            summary['threshold']=round(chosen,3)
        summary[split]={'v1_pixel':metrics(old,gt,.46),'v2_pixel':metrics(new,gt,chosen),
                        'v1_grid':metrics(og,gg,.46),'v2_grid':metrics(ng,gg,chosen)}
        old_components=[];new_components=[];gt_components=[]
        for i,(_,_,id) in enumerate(data[split]):
            usable=(rgb_all[i].max(2).mean()/255>=.18 and (skies[i]>=.6).mean()>=.12)
            oc=component(og[i]>=.46) if usable else np.zeros((16,16),bool)
            nc=component(ng[i]>=chosen) if usable else np.zeros((16,16),bool)
            gc=component(gg[i])
            old_components.append(oc);new_components.append(nc);gt_components.append(gc)
            cases.append(dict(id=id,split=split,old_iou=metrics(og[i:i+1],gg[i:i+1],.46)['iou'],
                              new_iou=metrics(ng[i:i+1],gg[i:i+1],chosen)['iou']))
        summary[split]['v1_selected_component']=metrics(np.array(old_components),np.array(gt_components))
        summary[split]['v2_selected_component']=metrics(np.array(new_components),np.array(gt_components))
        # Fixed evenly spaced examples, plus worst v2 IoU. Local research images only.
        indices=sorted(set([0,len(gt)//3,2*len(gt)//3,len(gt)-1]+[min(range(len(gt)),key=lambda i:cases[-len(gt)+i]['new_iou'])]))
        sheet=Image.new('RGB',(4*240,len(indices)*260+32),'white');draw=ImageDraw.Draw(sheet)
        for j,title in enumerate(['Photograph','Ground truth','v1 color rule','v2 trained cloud']):draw.text((j*240+8,8),title,fill='black')
        for row,i in enumerate(indices):
            variants=[Image.fromarray(rgb_all[i]),Image.fromarray((gt[i]*255).astype('uint8')),
                      Image.fromarray(((old[i]>=.46)*255).astype('uint8')),Image.fromarray(((new[i]>=chosen)*255).astype('uint8'))]
            for col,im in enumerate(variants):sheet.paste(im.resize((240,240)),(col*240,row*260+32))
            draw.text((8,row*260+272),data[split][i][2],fill='black')
        sheet.save(out/f'{split}-comparison.jpg')
        np.savez_compressed(out/f'{split}-predictions.npz',old=og,new=ng,truth=gg,ids=[s[2] for s in data[split]])
    (out/'metrics.json').write_text(json.dumps(summary,indent=2))
    with (out/'per-image.csv').open('w') as f:
        writer=csv.DictWriter(f,fieldnames=list(cases[0]));writer.writeheader();writer.writerows(cases)
    print(json.dumps(summary,indent=2),flush=True)
    assert summary['test']['v2_grid']['iou']>summary['test']['v1_grid']['iou'], 'Do not ship a regression'
    # CPU export must preserve the original model's output on real pixels.
    example=data['val'][0][0].astype(np.float32).transpose(2,0,1)[None]
    with torch.no_grad(): expected=wrapper(torch.from_numpy(example)).numpy()
    np.testing.assert_allclose(cloud.run(None,{'rgb':example})[0],expected,rtol=1e-4,atol=1e-5)

if __name__=='__main__':main()
