# openssl-keypair-encryption
Oké: Openssl public-private Keypair Encryption wrapper

Copy the Oké script to your project working directory:
`bash
 % git clone https://github.com/antonycc/openssl-keypair-encryption.git
 % cp openssl-keypair-encryption/open-ssl-pk-enc.sh <your project folder>/.
 %` 

First we have an empty list of recipients:
`bash
 % ./open-ssl-pk-enc.sh list-recipients
 %`
sdf

and one keypairs, non of which we will use as a recipient:
`bash
 % ./open-ssl-pk-enc.sh list-available-keypairs
[/Users/antony/.ssh/] /Users/antony/.ssh/test123 (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/test456 (.pem format)
 %`
 
 Generate a new keypair:
`bash
 % ./open-ssl-pk-enc.sh add-recipient /Users/antony/.ssh/test789.pem
Found .pem "/Users/antony/.ssh/test789.pem" extracting the public key and adding to "recipients"
Enter pass phrase for /Users/antony/.ssh/test789.pem:
writing RSA key
[recipients/] test789 (PEM is available locally in /Users/antony/.ssh)
 % ./open-ssl-pk-enc.sh list-available-keypairs               
[/Users/antony/.ssh/] /Users/antony/.ssh/antony-macbookpro-projects.pem (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/antony.cartwright@jira.upc.biz-public.pem (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/test456.pem (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/antony.cartwright@sjiraprojects.upc.biz-public.pem (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/test123.pem (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/antony.cartwright@jira.upc.biz-private.pem (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/antony.cartwright@sjiraprojects.upc.biz-private.pem (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/test789.pem?} (.pem format, installed to recipients)
[/Users/antony/.ssh/] /Users/antony/.ssh/antonycc (RSA format)
[/Users/antony/.ssh/] /Users/antony/.ssh/polycode-mbp-2019-03-02 (RSA format)
[/Users/antony/.ssh/] /Users/antony/.ssh/diyaccounting (RSA format)
[/Users/antony/.ssh/] /Users/antony/.ssh/id_rsa (RSA format)
`

Encrypt a local secret file:
`bash 
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
`

Delete then decrypt the secret file to restore:
`bash
 % cat secret-files.txt
test-data/test-clear-file.txt
 % cat test-data/test-clear-file.txt
test
1
2
3
4
 % ls -l test-data/test-clear-file.txt
-rw-r--r--  1 antony  staff  13 Jan 30 23:11 test-data/test-clear-file.txt
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
`

Remove the recipient added for this demonstration:
`bash
 % ./open-ssl-pk-enc.sh list-recipients
[recipients/] test789 (PEM is available locally in /Users/antony/.ssh)
 % ./open-ssl-pk-enc.sh remove-recipient test789 
 % ./open-ssl-pk-enc.sh list-recipients         
 % ./open-ssl-pk-enc.sh list-available-keypairs                                                           
[/Users/antony/.ssh/] /Users/antony/.ssh/test456.pem (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/test123.pem (.pem format)
[/Users/antony/.ssh/] /Users/antony/.ssh/test789.pem (.pem format)
 % `
