import subprocess
import time
import os.path

import torch
import numpy as np

from neml2 import postprocessing

nbatch = 2000
ntime = [250, 500, 750, 1000, 2500, 5000, 7500, 10000]
repeat = 5

neml2_runner = "/home/messner/packages/neml2/build/runner/runner"
# models = ["cubic"]
# integrations = ["coupled-implicit", "decoupled-explicit", "decoupled-implicit"]
models = ["triclinic"]
integrations = ["coupled-implicit", "decoupled-explicit"]
driver_name = "driver"

device = "cuda:1"

# results_name = "result.pt"
results_name = "result-triclinic.pt"


def run_single(fname, nt):
    subprocess.run(
        [
            neml2_runner,
            fname,
            driver_name,
            "nstep=%i" % nt,
            "nbatch=%i" % nbatch,
            "device=%s" % device,
        ],
        check=True,
    )


def load_results(fname):
    return {
        n.split("/")[-1]: v for n, v in torch.jit.load(fname).output.named_buffers()
    }


if __name__ == "__main__":
    for model in models:
        with open("%s_time.txt" % model, "w") as tf:
            tf.write("\t\t\t" + "\t\t".join(map(str, ntime)) + "\n")
            print(model)
            for integration in integrations:
                tf.write("%s:\t" % integration)
                print(integration)
                inp = os.path.join(model, integration) + ".i"
                for nt in ntime:
                    print(nt)
                    timings = []
                    for _ in range(repeat):
                        t1 = time.time()
                        run_single(inp, nt)
                        t2 = time.time()
                        timings.append(t2 - t1)
                    mean = np.mean(timings)
                    tf.write("%e\t" % mean)
                    # Store data, we just want the first and last time steps
                    results = load_results(results_name)
                    fstore = "%s-%s-%i.pt" % (model, integration, nt)
                    torch.save(
                        {
                            "orientation": results["orientation"][[0, -1]],
                            "elastic_strain": results["elastic_strain"][[0, -1]],
                        },
                        fstore,
                    )

                tf.write("\n")
