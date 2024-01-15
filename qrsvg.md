# Url
## without caption
[https://github.com/tdewin/pandoc-lua-timo-filters](qr://testout/media/qr-lua-filters.svg){black="#004600"}

## with caption
![https://github.com/tdewin/pandoc-lua-timo-filters](qr://testout/media/qr-lua-filters-c.svg){white="#eeffee"}

# Wifi Sharing

[WIFI:S:MYSSID;T:WPA;P:MYSECUREPASSWORD;](qr://testout/media/wifi.svg){black="#004600" white="#eeffee"}

# Contact Sharing

```qr://testout/media/vcard.svg {black="#004600" white="#eeffee" alt="vCard" docsz="near600"}
BEGIN:VCARD
VERSION:4.0
FN: John Doe
N:Doe;John;;Dr;
TEL;TYPE=cell:+3221234567
EMAIL;TYPE=work:john.doe@fakeidentity.be
ORG:FakeIdentity
TITLE:Identity Engineering Team Lead
END:VCARD
```


# How to

```bash
pandoc -L qrsvg.lua qrsvg.md -o testout/qr.docx
```