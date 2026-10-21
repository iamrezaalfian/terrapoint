# Direktori Sertifikat SSL / TLS

Letakkan sertifikat SSL Anda di sini jika mengaktifkan HTTPS port 443 pada Nginx:
- `cert.pem` (atau `fullchain.pem`)
- `key.pem` (atau `privkey.pem`)

Atau gunakan Certbot di host OS:
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d terrapoint.domainanda.com
```
