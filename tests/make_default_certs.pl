
use strict;
use Scripts;

my $DataPath = '/var/opt/cprocsp/tmp/';

sub DisableInstallCertWindow($);

#-----------------------------------------------------------------------------
{

    my $cryptcp = '/opt/cprocsp/bin/amd64/cryptcp';
    my $csptest = '/opt/cprocsp/bin/amd64/csptest';
    
    #RunCmd("DelCert", $cryptcp . ' -delcert -m -yes -dn CN= -nochain');
    RunCmd("DelCert", $cryptcp . ' -delcert -u -yes -dn CN= -nochain');
    RunCmd("DelCert", $csptest . ' -notime -noerrorwait -keyset -silent -deletekeyset -pattern "" -verifyco -provtype 75 -provider "Crypto-Pro GOST R 34.10-2001 KC1 CSP" ');
    
    #delete ssl certs and keys
    RunCmd('DelCertRSA', 'rm ' . $DataPath . 'stunnelsrvRSA.cer') if (-e $DataPath . 'stunnelsrvRSA.cer');
    RunCmd('DelCertRSA', 'rm ' . $DataPath . 'stunnelclnRSA.cer') if (-e $DataPath . 'stunnelclnRSA.cer');
    RunCmd('DelKeyRSA', 'rm ' . $DataPath . 'stunnelsrvRSA.key') if (-e $DataPath . 'stunnelsrvRSA.key');
    RunCmd('DelKeyRSA', 'rm ' . $DataPath . 'stunnelclnRSA.key') if (-e $DataPath . 'stunnelclnRSA.key');

    RunCmd('DelCertPem', 'rm ' . $DataPath . 'stunnelcln.pem') if (-e $DataPath . 'stunnelcln.pem');
    RunCmd('DelCertPem', 'rm ' . $DataPath . 'stunnelsrv.pem') if (-e $DataPath . 'stunnelsrv.pem');

    #make RSA certs
    RunCmd('MakeCertAndKeyRSA', 'openssl req -x509 -newkey rsa:2048 -keyout ' . $DataPath . 'stunnelsrvRSA.key -nodes -out ' . $DataPath . 'stunnelsrvRSA.cer -subj \'/CN=srvRSA/C=RU\' ');
    RunCmd('MakeCertAndKeyRSA', 'openssl rsa -in ' . $DataPath . 'stunnelsrvRSA.key -out ' . $DataPath . 'stunnelsrvRSA.key');

    RunCmd('MakeCertAndKeyRSA', 'openssl req -x509 -newkey rsa:2048 -keyout ' . $DataPath . 'stunnelclnRSA.key -nodes -out ' . $DataPath . 'stunnelclnRSA.cer -subj \'/CN=clnRSA/C=RU\' ');
    RunCmd('MakeCertAndKeyRSA', 'openssl rsa -in ' . $DataPath . 'stunnelclnRSA.key -out ' . $DataPath . 'stunnelclnRSA.key');
    
    #make GOST certs
    RunCmd('MakeDSRF', "/opt/cprocsp/sbin/amd64/cpconfig -hardware rndm -add cpsd -name 'cpsd rng' -level 2 ");
    RunCmd('MakeDSRF', "/opt/cprocsp/sbin/amd64/cpconfig -hardware rndm -configure cpsd -add string /db1/kis_1 /var/opt/cprocsp/dsrf/db1/kis_1");
    RunCmd('MakeDSRF', "/opt/cprocsp/sbin/amd64/cpconfig -hardware rndm -configure cpsd -add string /db2/kis_1 /var/opt/cprocsp/dsrf/db2/kis_1");
    RunCmd('MakeDSRF', "cp ./mydsrf /var/opt/cprocsp/dsrf/db1/kis_1");
    RunCmd('MakeDSRF', "cp ./mydsrf /var/opt/cprocsp/dsrf/db2/kis_1");
    
    #new certs
    RunCmd('MakeCertGOST', "/opt/cprocsp/bin/amd64/cryptcp -creatcert -provtype 81 -provname 'Crypto-Pro GOST R 34.10-2012 KC1 Strong CSP'  -silent -rdn \'CN=127.0.0.1\' -cont \'\\\\.\\HDIMAGE\\localhost_cont\' -certusage 1.3.6.1.5.5.7.3.1 -ku -du -ex -ca http://cryptopro.ru/certsrv -enable-install-root");
    RunCmd('MakeCertGOST', "/opt/cprocsp/bin/amd64/cryptcp -creatcert -provtype 81 -provname 'Crypto-Pro GOST R 34.10-2012 KC1 Strong CSP'  -silent -rdn \'E=cln512ecryptopro.ru, CN=cln512e\' -cont \'\\\\.\\HDIMAGE\\cln512e\' -certusage 1.3.6.1.5.5.7.3.2 -ku -du -both -ca http://cryptopro.ru/certsrv -enable-install-root");
 
    #old certs (могут быть ошибки из-за упоминания о старых сертификатах)
    #RunCmd('MakeCertGOST', "/opt/cprocsp/bin/amd64/cryptcp -creatcert -provtype 75 -provname 'Crypto-Pro GOST R 34.10-2001 KC1 CSP'  -silent -rdn \'CN=127.0.0.1\' -cont \'\\\\.\\HDIMAGE\\localhost_cont\' -certusage 1.3.6.1.5.5.7.3.1 -ku -du -ex -ca http://cryptopro.ru/certsrv -keysize 512 -hashalg 1.2.643.2.2.9 -enable-install-root");
    #RunCmd('MakeCertGOST', "/opt/cprocsp/bin/amd64/cryptcp -creatcert -provtype 75 -provname 'Crypto-Pro GOST R 34.10-2001 KC1 CSP'  -silent -rdn \'E=cln512ecryptopro.ru, CN=cln512e\' -cont \'\\\\.\\HDIMAGE\\cln512e\' -certusage 1.3.6.1.5.5.7.3.2 -ku -du -both -ca http://cryptopro.ru/certsrv -keysize 512 -hashalg 1.2.643.2.2.9 -enable-install-root");
    
    #export certs
    RunCmd('Safe cert in '.$DataPath, "/opt/cprocsp/bin/amd64/certmgr -export -cert -dest ".$DataPath."stunnelsrv.cer -dn CN=127.0.0.1");
    RunCmd('Safe cert in '.$DataPath, "/opt/cprocsp/bin/amd64/certmgr -export -cert -dest ".$DataPath."stunnelcln.cer -dn CN=cln512e");

    RunCmd('Make cert PEM format in '.$DataPath, "openssl x509 -inform DER -in " . $DataPath . "stunnelcln.cer -out " . $DataPath . "stunnelcln.pem");
    RunCmd('Make cert PEM format in '.$DataPath, "openssl x509 -inform DER -in " . $DataPath . "stunnelsrv.cer -out " . $DataPath . "stunnelsrv.pem");
}


__END__
