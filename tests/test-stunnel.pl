use strict;
use Scripts;

print "\n\n--------MAKE DEFAULT CERTS--------\n";
print "----------------------------------\n\n";

print "sudo perl make_default_certs.pl:\n\n";
system("sudo perl make_default_certs.pl");

sleep(1);

print "\n\n--------START STUNNEL-------------\n";
print "----------------------------------\n\n";

print "sudo perl stunnel.pl local:\n\n";
system("sudo perl stunnel.pl local");

sleep(1);

print "\n\n--------START CLIENT--------------\n";
print "----------------------------------\n\n";

print "sudo perl stunnel_client.pl local > client_log &:\n\n";
system("sudo perl stunnel_client.pl local > client_log &");


sleep(1);

print "\n\n--------START SERVER--------------\n";
print "----------------------------------\n\n";

print "sudo perl stunnel_server.pl:\n\n";
system("sudo perl stunnel_server.pl");

sleep(3);

print "\n\n--------CLIENT LOG----------------\n";
print "----------------------------------\n\n";

print "cat client_log:\n\n";
system("cat client_log");