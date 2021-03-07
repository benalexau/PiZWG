# Kubernetes openHAB Example

This directory provides a starting point for using openHAB with PiZWG on
Kubernetes. It implements a deployment where `socat` provides a USB device in
the same pod as openHAB is deployed.

The example requires a namespace:

    kubectl create namespace openhab

You will need to obtain `ser2net.crt` and `pizwg-client.pem` from the PiZWG
backup. You will need to create a secret containing these certificates. If
using Sealed Secrets the following commands will work:

    kubectl -n openhab create secret generic pizwg-certificates --dry-run=client --from-file=ser2net.crt=./ser2net.crt --from-file=pizwg-client.pem -o json > /tmp/mysecret.json
    kubeseal < /tmp/mysecret.json > 10-pizwg-certificates.json
    rm /tmp/mysecret.json
    kubectl apply -f 10-pizwg-certificates.json

Verify the secret is avaialble:

    kubectl -n openhab get secrets

Review the `openhab.yaml` and make changes that are appropriate for your needs.
Pay particular attention to the timezone, storage class, `socat` IP address and
timeout settings. Once satisfied, deploy openHAB using:

    kubectl apply -f openhab.yaml
