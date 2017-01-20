## triton dehydrated

[dehydrated](https://github.com/lukas2511/dehydrated) hook script to set up
certificates automatically for Triton, using DNS challenges. Enabled via CNS.

To use this you need to have CNS set up and publically resolvable. Then, either
fill `domains.txt` with the names of the CNS endpoints for the Triton services
(currently `adminui`, `cloudapi`, `docker` and `manta` are supported), or fill
it with names you have CNAME'd to those CNS service names.

If you CNAME a name, you will need to put a CNAME at `_acme-challenge.name` as
well, in order to make the DNS challenges work.

Once you've filled out `domains.txt`, simply run `./run -c`. You can even do
this from cron.
