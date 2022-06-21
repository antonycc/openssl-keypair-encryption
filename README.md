# openssl-keypair-encryption
Oké: Openssl public-private Keypair Encryption wrapper

Copy the Oké script to your project working directory:
```bash
 % git clone https://github.com/antonycc/openssl-keypair-encryption.git
 % cp openssl-keypair-encryption/open-ssl-pk-enc.sh <your project folder>/.
``` 

First we have an empty list of recipients:
```bash
 % mkdir -p recipients
 % ./open-ssl-pk-enc.sh list-recipients
 %
```

We have two available keypairs, none of which we will use as a recipient:
```bash
 % ./open-ssl-pk-enc.sh list-available-keypairs
[/Users/antony/.ssh/] /Users/antony/.ssh/test123 (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/test456 (.pem format)
 %
```
 
Generate a new keypair:
```bash
 % ./open-ssl-pk-enc.sh generate-keypair test789
Generating RSA private key, 2048 bit long modulus
...............+++
..................+++
e is 65537 (0x10001)
Enter pass phrase for test789.pem:
Verifying - Enter pass phrase for test789.pem:
-rw-------  1 antony  staff  1743 Feb  2 03:02 /Users/antony/.ssh/test789.pem
antony@Antonys-MacBook-Pro openssl-keypair-encryption % 
 % ./open-ssl-pk-enc.sh add-recipient /Users/antony/.ssh/test789.pem
Found .pem "/Users/antony/.ssh/test789.pem" extracting the public key and adding to "recipients"
Enter pass phrase for /Users/antony/.ssh/test789.pem:
writing RSA key
[recipients/] test789 (PEM is available locally in /Users/antony/.ssh)
 % ./open-ssl-pk-enc.sh list-available-keypairs               
[/Users/antony/.ssh/] /Users/antony/.ssh/test456.pem (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/test123.pem (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/test789.pem (.pem format)
 %
```

Add the new keypair as a recipient:
```bash
 % ./open-ssl-pk-enc.sh add-recipient /Users/antony/.ssh/test789.pem
Found .pem "/Users/antony/.ssh/test789.pem" extracting the public key and adding to "recipients"
Enter pass phrase for /Users/antony/.ssh/test789.pem:
writing RSA key
[recipients/] test789 (PEM is available locally in /Users/antony/.ssh)
 % ./open-ssl-pk-enc.sh list-available-keypairs               
[/Users/antony/.ssh/] /Users/antony/.ssh/test456.pem (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/test123.pem (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/test789.pem (.pem format, installed to recipients)
 %
```

Encrypt a local secret file:
```bash 
 % ls -lrt           
total 48
-rw-r--r--  1 antony  staff  1211 Jan 30 23:11 LICENSE
-rw-r--r--  1 antony  staff    30 Jan 30 23:11 secret-files.txt
drwxr-xr-x  3 antony  staff    96 Jan 31 03:09 test-data
-rw-r--r--  1 antony  staff    86 Feb  2 02:41 README.md
-rwxr-xr-x  1 antony  staff  9138 Feb  2 03:11 open-ssl-pk-enc.sh
drwxr-xr-x  3 antony  staff    96 Feb  2 03:11 recipients
 % cat secret-files.txt
test-data/test-clear-file.txt
 % cat test-data/test-clear-file.txt
test
1
2
3
4
 % ./open-ssl-pk-enc.sh encrypt
a test-data/test-clear-file.txt
-rw-r--r--  1 antony  staff  2048 Feb  2 03:14 archive.tar
Encrypting "archive.tar" with public key "recipients/test789.public"
a test789.key.bin.enc
bytes read   :    2048
bytes written:    2080
a test789.archive.tar.enc
-rw-r--r--  1 antony  staff  5120 Feb  2 03:14 archive.enc.tar
 % ls -lrt                     
total 64
-rw-r--r--  1 antony  staff  1211 Jan 30 23:11 LICENSE
-rw-r--r--  1 antony  staff    30 Jan 30 23:11 secret-files.txt
drwxr-xr-x  3 antony  staff    96 Jan 31 03:09 test-data
-rw-r--r--  1 antony  staff    86 Feb  2 02:41 README.md
-rwxr-xr-x  1 antony  staff  9138 Feb  2 03:11 open-ssl-pk-enc.sh
drwxr-xr-x  3 antony  staff    96 Feb  2 03:11 recipients
-rw-r--r--  1 antony  staff  5120 Feb  2 03:14 archive.enc.tar
 % tar -t --file archive.enc.tar
test789.key.bin.enc
test789.archive.tar.enc
 %
```

Delete then decrypt the secret file to restore:
```bash
 % rm test-data/test-clear-file.txt                                                                   
 % ls -l test-data/test-clear-file.txt                                                                    
ls: test-data/test-clear-file.txt: No such file or directory
 % ./open-ssl-pk-enc.sh decrypt       
recipient_key_encrypted = "test789.key.bin.enc"
Decrypting "test789.archive.tar.enc" with public key "/Users/antony/.ssh/test789.pem"
x test789.key.bin.enc
x test789.archive.tar.enc
Enter pass phrase for /Users/antony/.ssh/test789.pem:
bytes read   :    2080
bytes written:    2048
x test-data/test-clear-file.txt
 % ls -l test-data/test-clear-file.txt
-rw-r--r--  1 antony  staff  13 Jan 30 23:11 test-data/test-clear-file.txt
 % cat test-data/test-clear-file.txt
test
1
2
3
4
 %
```

Remove the recipient added for this demonstration:
```bash
 % ./open-ssl-pk-enc.sh list-recipients
[recipients/] test789 (PEM is available locally in /Users/antony/.ssh)
 % ./open-ssl-pk-enc.sh remove-recipient test789 
 % ./open-ssl-pk-enc.sh list-recipients         
 % 
```
