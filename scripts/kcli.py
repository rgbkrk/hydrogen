#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Simple client utility to mock GET /api/kernelspecs from the notebook server,
return local JSON.

This differs in that resources are returned as if consumed locally (PNGs, etc.),
rather than a full notebook server.
"""

import glob
import json
import os
import sys
import traceback

import jupyter_client

class KernelClientAPI():

    def __init__(self):
        self.km = jupyter_client.multikernelmanager.MultiKernelManager()
        self.ksm = jupyter_client.kernelspec.KernelSpecManager()

    def kernelspec_model(self, kernel_name):
        '''kernelspec_model bundles up a kernel spec with its resources, similar
        to the Jupyter API for kernelspecs'''
        spec = self.ksm.get_kernel_spec(kernel_name)
        kernel_spec = {'name': kernel_name}
        kernel_spec['spec'] = spec.to_dict()
        kernel_spec['resources'] = resources = {}
        resource_dir = spec.resource_dir

        # Logos are absolute paths from the various kernel directories
        logos = glob.glob(os.path.join(resource_dir, 'logo-*'))
        for logo_file in logos:
            fname = os.path.basename(logo_file)
            no_ext, _ = os.path.splitext(fname)
            resources[no_ext] = logo_file

        return kernel_spec

    def kernelspecs_model(self):
        '''kernelspecs_model returns a dictionary of all the kernelspecs on the
        system, including the default
        '''
        model = {}
        model['default'] = self.km.default_kernel_name
        model['kernelspecs'] = {}

        model['kernelspecs-errors'] = {}

        for kernel_name in self.ksm.find_kernel_specs():
            try:
                kernel_spec = self.kernelspec_model(kernel_name)
                model['kernelspecs'][kernel_name] = kernel_spec
            except Exception:
                tb = traceback.format_exc()
                message = "Failed to load kernel spec.\n{}".format(tb)
                model['kernelspecs-errors'][kernel_name] = message
        return model

if __name__ == "__main__":
    kernel_client = KernelClientAPI()
    model = kernel_client.kernelspecs_model()
    json.dump(model, sys.stdout, indent=2)

