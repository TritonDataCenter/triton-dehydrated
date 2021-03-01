# triton-dehydrated

[dehydrated](https://github.com/lukas2511/dehydrated) hook script to set up
certificates automatically for Triton, using DNS challenges. Requires CNS.

## How to use: headnode services (CloudAPI etc)

 1. Set up CNS in your Triton deployment (see
    [the CNS operator guide](https://github.com/joyent/triton-cns/blob/master/docs/operator-guide.md)).
    We'll assume for the sake of examples here that the CNS suffix for the
    DC is `dc1.cns.example.com`.
 2. Decide either to use the CNS-generated names for `cloudapi`, `adminui` and
    `docker` (which are `cloudapi.dc1.cns.example.com` etc), or set up the
    DNS names you want for each service to be CNAMEs to those names. You may
    also choose to use ECDSA certificates instead (with domains.ecdsa.txt).
    **For CMON, you *must* use the cns generated name and ECDSA certificates.**
 3. If you set up `dc1.api.example.com` as a CNAME to
    `cloudapi.dc1.cns.example.com`, then you must also set up
    `_acme-challenge.dc1.api.example.com` as a CNAME to
    `_acme-challenge.cloudapi.dc1.cns.example.com` (and similarly for
    the other services).
 4. Now log into your Triton headnode and extract a release tarball of
    `triton-dehydrated` into `/opt/dehydrated`:

    <!-- markdownlint-disable MD013 -->
    ```shell
    mkdir -p /opt/dehydrated
    latest=$(curl -s https://api.github.com/repos/joyent/triton-dehydrated/releases/latest | json assets.0.browser_download_url)
    curl -L "$latest" | gtar --no-same-owner -zxv -C /opt/dehydrated
    ```
    <!-- markdownlint-enable MD013 -->

 5. Copy the example `domains.txt.example` to `domains.txt` and edit it:

    ```shell
    cp /opt/dehydrated/domains.txt{.example,}
    vi /opt/dehydrated/domains.txt
    ```

    List on each line the DNS name you've chosen to use for that service (e.g.
    `cloudapi.dc1.cns.example.com` or `dc1.api.example.com`)
 6. Now get your first set of RSA certificates.

    ```shell
        [root@headnode (emy-15) ~]$ /opt/dehydrated/dehydrated -c --accept-terms
        # INFO: Using main config file /opt/dehydrated/config
        Processing adminui.emy-15.cns.joyent.us
         + Generating private key...
         * Generating signing request...
         * Requesting challenge for adminui.emy-15.cns.joyent.us...
        Successfully updated VM de569b37-4198-4b8b-b43e-b97a471d13ac
        OK: deployed dns token for adminui.emy-15.cns.joyent.us successfully
         * Responding to challenge for adminui.emy-15.cns.joyent.us...
        Successfully updated VM de569b37-4198-4b8b-b43e-b97a471d13ac
         * Challenge is valid!
         * Requesting certificate...
         * Checking certificate...
         * Done!
         * Creating fullchain.pem...
         * Walking chain...
        OK: adminui certificate deployed, and adminui restarted
         * Done!
        ....
    ```

 8. To get ECDSA certificates, use the `-f config.ecdsa` parameter.

    ```shell
    /opt/dehydrated/dehydrated -c -f config.ecdsa
    ```

 9. Once you've done the first run successfully, you should add the renewal
    command to cron:

    ```shell
    [root@headnode (emy-15) ~]$ crontab -e
    1 16 * * * /opt/dehydrated/dehydrated -c
    1 25 * * * /opt/dehydrated/dehydrated -c -f /opt/dehydrated/config.ecdsa
    ```

    Note that the renewal process will restart SDC services as part of
    deploying certificates, which necessarily causes a small window of
    downtime. You should set the time and day of the week here and advise
    your users of this regularly scheduled event before using cron to
    automate renewal.

## How to use: inside a user container on Triton

This hook script can also be used inside a regular user container on Triton to
obtain a certificate for any name CNAME'd to the container's CNS name. This
should work on LX-branded zones as well.

 1. Either use the Triton public cloud, or set up CNS in your Triton
    deployment (see
    [the CNS operator guide](https://github.com/joyent/triton-cns/blob/master/docs/operator-guide.md)).
    We'll assume for the sake of example here that the CNS suffix for the
    DC is
    ```
    us-west-1.triton.zone
    ```
 2. Find the CNS-generated name for your container. One way to do this is
    to look for the `dns_names` array in the output of
    ```shell
    triton inst get <instance>
    ```
    As an example, let's consider
    ```
    blog.svc.3c330096-89e6-11e7-9f13-23d71a63353e.us-west-1.triton.zone
    ```
 3. Set up your desired DNS name as a CNAME to this CNS-generated name. If you
    are hosting the root of your domain, it's also fine to just set up a
    regular A record instead, as long as you also deploy a TXT record
    containing the full UUID of the container. We'll use
    ```
    blog.example.com
    ```
    and CNAME it to
    ```
    blog.svc.3c330096-89e6-11e7-9f13-23d71a63353e.us-west-1.triton.zone
    ```
 4. Set up `_acme-challenge.<domain>` as a CNAME to
    `_acme-challenge.<cnsdomain>`. We'll set up
    ```
    _acme-challenge.blog.example.com
    ```
    as a CNAME to
    ```
    _acme-challenge.blog.svc.3c330096-89e6-11e7-9f13-23d71a63353e.us-west-1.triton.zone
    ```
 5. Inside the container, download and extract the `dehydrated.tar.gz` file
    from the [latest GitHub release](https://github.com/joyent/triton-dehydrated/releases/)
    into a directory.
 6. Create a new file `domains.txt` in the directory containing just one line
    with the full domain name you want on the certificate, e.g.
    ```
    blog.example.com
    ```
 7. Get the first certificate by running
    ```shell
    ./dehydrated -c --accept-terms
    ```

Now you will find your certificate files in `./certs/blog.example.com/`. You
should configure your webserver to get the private key and certificate file
(with chain) directly from this folder.

You can also create override hooks in a file named `override-hook`. The format
for this file is the same as for `dehydrated`'s hook file but should only have
the `deploy_cert` and/or `unchanged_cert` functions. Use override hooks in a
zone to do things like restart local services.

Finally, you can set up a cron job to re-run `./dehydrated -c` daily, or at
least once a week, pr (and then do a graceful reload of your web server
configuration).
