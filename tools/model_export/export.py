"""Export the Apache-2.0 U2NETP sky checkpoint; requires torch and onnx.

Download weights/u2netp_sky.pth from geohot/U-2-Net-tinygrad at
cba5242158611e39a505f732b4a78a3018f93a5b, then pass its path.
The wrapper keeps only the fused sky head (the upstream demo inverts it to exclude sky).
"""
import sys
from pathlib import Path
import torch
from u2net import U2NETP

class Sky(torch.nn.Module):
    def __init__(self, weights):
        super().__init__()
        self.net = U2NETP(3, 1)
        self.net.load_state_dict(torch.load(weights, map_location='cpu', weights_only=True))
    def forward(self, image):
        return self.net(image)[0]

if __name__ == '__main__':
    model = Sky(sys.argv[1]).eval()
    destination = Path(__file__).resolve().parents[2] / 'assets/models/sky_u2netp_v1.onnx'
    torch.onnx.export(model, torch.zeros(1, 3, 320, 320), str(destination),
                      input_names=['image'], output_names=['sky'], opset_version=17,
                      dynamo=False)
    print(destination, destination.stat().st_size)
