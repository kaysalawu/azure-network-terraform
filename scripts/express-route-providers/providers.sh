#!/bin/bash

az network express-route list-service-providers -o json > providers.json
python3 main.py
