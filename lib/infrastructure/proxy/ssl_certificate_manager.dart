import 'dart:convert';
import 'dart:io';

class SslCertificateManager {
  static const String caCertificatePem = '''-----BEGIN CERTIFICATE-----
MIIDUTCCAjmgAwIBAgIUYykdxz8GxEBLjr0HHSOg3iUjOWswDQYJKoZIhvcNAQEL
BQAwODEYMBYGA1UEAwwPQXBpTGFiIFByb3h5IENBMQ8wDQYDVQQKDAZBcGlMYWIx
CzAJBgNVBAYTAlVTMB4XDTI2MTAwMTA2NDYyMloXDTM2MDkyODA2NDYyMlowODEY
MBYGA1UEAwwPQXBpTGFiIFByb3h5IENBMQ8wDQYDVQQKDAZBcGlMYWIxCzAJBgNV
BAYTAlVTMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnYln+7VY/Yl0
Ri6u+eAE7aVxHf8JttgvG62pXBVwW7FORFpLDuxQh9J5SFmX8ssL9X6m5TWfxgXR
C4LEDIz1K2gxxhJZ8Nlv6qaNjTbfjUHJLjMgr67ipkfkIKOu8h9HdoKP3tnGbI76
5fjtPMl92XW/4ZndYz6gng79FoOPes1osUaqH0mT078M1rFlha4Me4A8aaTBXWFR
okcBta8tbXXWDVr3h9w0SHAuOBJusZrqbgfYtNoub62waWGbPbJZQlNsqcrwxI8G
mmTMSjX743go4g9yY0WWVV0j3Qead/0kS1obI2gBHW12JeKqkNoIyuj8TpkoZfll
3L5WH1u7VwIDAQABo1MwUTAdBgNVHQ4EFgQUrCA2J37xvma6AVv7uPanbEMp2dkw
HwYDVR0jBBgwFoAUrCA2J37xvma6AVv7uPanbEMp2dkwDwYDVR0TAQH/BAUwAwEB
/zANBgkqhkiG9w0BAQsFAAOCAQEAZGaZjXo5JE6ACQtebeoPeEXoQnEdtpp4Xo7i
hjFOo5iVDO+2b3nqzdDVvZ/qEk158j7XPkdCuO0twlAcMILEK42M+/Pj4jqss2s7
A0L5IoOWxQnXbop/Ix7n/7OZ2hNmLALvNMAYJphBn4xpAJHQW8iWCM3OBhuBQUIG
vrrvGgTyVuZtz4EHWI+8G6fpx5Qh87at+bBC07yeOGdcT3RujjMdp41VEYOT0/Nu
xQuziVGwjoapB17dyBPeJmGN6ye2fsW5mwAp63L15UjB6XiU/8Lublb31sJ1FKzc
Fizel9Aa/byZYNi+8mbj5Z6h28LVHn83j8AWAwGVCjCfVsmyUA==
-----END CERTIFICATE-----''';

  static const String caPrivateKeyPem = '''-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCdiWf7tVj9iXRG
Lq754ATtpXEd/wm22C8bralcFXBbsU5EWksO7FCH0nlIWZfyywv1fqblNZ/GBdEL
gsQMjPUraDHGElnw2W/qpo2NNt+NQckuMyCvruKmR+Qgo67yH0d2go/e2cZsjvrl
+O08yX3Zdb/hmd1jPqCeDv0Wg496zWixRqofSZPTvwzWsWWFrgx7gDxppMFdYVGi
RwG1ry1tddYNWveH3DRIcC44Em6xmupuB9i02i5vrbBpYZs9sllCU2ypyvDEjwaa
ZMxKNfvjeCjiD3JjRZZVXSPdB5p3/SRLWhsjaAEdbXYl4qqQ2gjK6PxOmShl+WXc
vlYfW7tXAgMBAAECggEAG8bkDkY6BC5N0agekxF0XQCsUskqydIRcFRtBb8D+i7n
qXawQFfblS8/0kl12MoDeExWGhkb7FsPMnPipIHgIsCy8gU/VY/JQ3sNf2Y7AZml
Yt+B9mgkL4SCjVy/FpL8U0GPI5CLg42sYItFLVArwAGajSlHl12uDWCAMI2O6Wxy
RWa3kUCjefqBu5JaVNcAa8zTT4aJwZMnxs0I5MiVVggavEbqgplTsOLvP2tnr0zS
4g9xZhnSO+ivGidARj402spftWRxP8D/XgPMgO8tTKANzhloIruEyLQomcYMKIkt
OXS7/FB6ijzNSclgcCfrpo+7iH6okraOCnojO218iQKBgQDeijFhpUJpA7D7fHJk
Vi8jQ1a0ufWrRB1Yk7ZCKCOQZwedyoOcIZ9H1gXkibhIhAXDXzmAV5hLznUaONlh
/1P4bRWqj6NMbXZNWYXrlmtywM+jl9Ln5pTttvL7zz4dSfcTHfQK0rg8WaKEMgYH
CaTQ+ZzFSckLqPaBDGNwcaifSQKBgQC1OSwO3bGuXxH2Uq27c6JI+/bn4cytgeO3
nXZsz9pHh8zEVQPkJPFcc90Nq1MilaaPv7hkOgzDhUDk5/sunB/m5c6tpe6PJUcn
2H0UJlK1+rfMH7UQeJloYOT4ooOsHG/m3xXbTLjJ2v3PXkkqgBl/JIKzUdDaWISk
1SLo1YFlnwKBgDH72BuWgtQTgCz8RrVCplPFTDRLkGJnai/6/XTejx5gBdXrJqRq
6Nu5tpkeVcXz4VeAi+nHwu1D8glxu2HHd5TU64jjuknwTCITeYDwyDF+HSUhdL2h
jNHXxbvJUKpDcrtYfvfvXHIxr88BbVknUV2esxec+wsjaDqUDcGzxawBAoGBAIGn
rcXVBtJiYk+BR5rdWDYvTq8H9ZANZgZwOdIPw3N5zR6KVIZdh/FFU9n7wTb1Kn2e
BSZwAcHBDHS5JBRszsY7lGrYVJ1FZmszkAligbqA7g60gK6QGfF7oVXhr6LrlYPw
B4smkO6aJwy9wEsP6y3zyS7SUkJlIkFr29YJKtKxAoGBAKFS5rIOPmmH1yRZkOxF
g7ZTkebfdJciM8+zOpf9JLaNcvAq/Ylb7damZnRzvbtXFKIM9ucklsWKdgM8lFhR
GZa/d+U/FDG4pr8/75Ppi278Gbx9MdX87ZbZJSNDpPXoBGq5y+1UFfhI0q+TO+d4
+ahIDvSBFAWw14aHCkBkwLPn
-----END PRIVATE KEY-----''';

  static const String leafPrivateKeyPem = '''-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCkErff+IYZIJdP
5IZEHOfk6pGLUjaBGR4WVseW0B7jKT72cbfMgRuRWhhIkpcJq3DktKbVzQlpEBDy
1+0eXuAhoq0Xo2leCMQfOc/wJudFjN6RSfFUK6V7BIYO0gfABN6P46mwAA7dZzYw
RddIExB2UfhrhkIH6b2NXwsv5+sx5MT0bfHJX8N14P7pC/oP7ZCn13iAWxAhMvjm
B3u/HR3qfj7F42OhKBsUI335MX2eDiVvSuMLxFfkskNDveSQk/1RI6bhiu13amvW
69ycnY2n437hqE7OOKd8LYYm+OVT2OtXs7+8Eu0DEamwsL/E+21LDpn6z0xJlrW4
Ppv69HELAgMBAAECggEAOoovLutGNTrqoefAfBbwKj4DNflcVw12LbRCvC1/h79U
pquGT6IVCvRhS6t51kpkGkXWbNweKm1ADtU51ic1wup+5bs5QgLQru96oI3Q4IDV
fHMsdsKn5U+E4U7Q0xMpsZ8iERjENPy5WdnhaObcbcrrXrnlX1tndURfAnW19fO9
8cLBxErxen6ynkeUCEPohrBsiO+IgSafmOiMEPtMiuN5o3tpZtb8yRPsRrJ4Nb2O
rLCCvXlKq2eBpyBnozpkpEcXJaxpj4UHxTpK7oKIKRAh7Uv983+MyQVuDihg7xSV
UYFEjr3ars46bk7T99MZcitfi901AdnK/7Ylu2U0UQKBgQDgln134RCOFGdEY16G
BLXXE5QkCXIbdACtoh9VK6WBXXpc8VPsj7CKctQq2DQ/JQ5rysaGrzWmiCQBM5DE
7WGDTWeT0T3fZcm4I/pSEQoG8K+exQnTGY4iTsMyQizxG2x9J/Y+Es+dVCLeCofX
bz3L7kDCaCSP8OHz6ew20EJLwwKBgQC7BXW7IsaLq0ksJF5T6axbigbtOw5LhUGc
+er28idP7w4wg9QRPKoBz6VAr3iNxIK8oPfCoM7Ceg8YT6GG0Q779iPY2uafKkP3
2SbbWDPdeRc5bAE7i1p0F5JMaORbOe3BmWqE3m73vaMY+xIT4+8q6Wx7x/95wmbG
dBBcuEcZGQKBgQCc0jh2Nt/adgDNzh04s51Nu0wcBcR5yvyWQbhjPoDo3h8NOy4A
5yy84AWqjSGeXf+94O/TKBDsYe/SLvGNsLwAdVI380mi7m52eBjYqTE5O2NGGAwO
LbAD4L+IHpFHIoEUu4zEN1plX1ShevTzx6d8+LabiSDOqcL9EIByneVNBQKBgEKX
5xwDff8ttphpOs1WX3EY7O58INLzWDG1K91SzHzB+qN7zX91wnNypL0rvhl857CT
AKXk7LqDC+z0Lef7eQJu2sTU7VmvixQt1pA0EAPEomhn9Ohm7oZ3/jgHAYkaT3ao
Ui2NpqXAeNrkS8OZXghBpcdNp8KLXl075redRnPBAoGAZGG9MGHmYDujou6G3qvJ
rd42rOm3eqiD/dd5HyT3g/L97W95eXmcpHZOge/Mn2670pKeSun+DmPoET83JAAi
rkgsDbLJDh5kQBo62Jgjv2E69DJvCCdZYqT6m4EhVUiEUTBzHTwbSt7y922bPU/d
pOvdLtHFVsOHLjO09Yuan44=
-----END PRIVATE KEY-----''';

  static final Map<String, SecurityContext> _hostContextCache = {};
  static final Map<String, Future<SecurityContext>> _inFlightGenerations = {};
  static String? _opensslPath;
  static Directory? _certTempDir;

  /// Default fallback security context presenting the CA certificate.
  static SecurityContext getSecurityContext() {
    final context = SecurityContext();
    context.useCertificateChainBytes(utf8.encode(caCertificatePem));
    context.usePrivateKeyBytes(utf8.encode(caPrivateKeyPem));
    return context;
  }

  /// Locates the OpenSSL binary on the current operating system.
  static Future<String?> _findOpenssl() async {
    if (_opensslPath != null) return _opensslPath;

    final candidates = [
      'openssl',
      '/usr/bin/openssl',
      '/opt/homebrew/bin/openssl',
      '/usr/local/bin/openssl',
      r'C:\Program Files\Git\usr\bin\openssl.exe',
      r'C:\Program Files\OpenSSL-Win64\bin\openssl.exe',
      r'C:\Program Files (x86)\OpenSSL-Win32\bin\openssl.exe',
    ];

    for (final candidate in candidates) {
      try {
        final res = await Process.run(candidate, ['version']);
        if (res.exitCode == 0) {
          _opensslPath = candidate;
          return _opensslPath;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Returns temporary certificate working directory with root CA and leaf key written.
  static Future<Directory> _getTempDir() async {
    if (_certTempDir != null && await _certTempDir!.exists()) {
      return _certTempDir!;
    }
    final systemTemp = Directory.systemTemp;
    final dir = Directory('${systemTemp.path}/apilab_certs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final caCertFile = File('${dir.path}/ca.crt');
    if (!await caCertFile.exists()) {
      await caCertFile.writeAsString(caCertificatePem);
    }
    final caKeyFile = File('${dir.path}/ca.key');
    if (!await caKeyFile.exists()) {
      await caKeyFile.writeAsString(caPrivateKeyPem);
    }
    final leafKeyFile = File('${dir.path}/leaf.key');
    if (!await leafKeyFile.exists()) {
      await leafKeyFile.writeAsString(leafPrivateKeyPem);
    }
    _certTempDir = dir;
    return dir;
  }

  /// Dynamically generates or returns a cached TLS SecurityContext for [host],
  /// containing a leaf certificate signed by ApiLab Proxy CA with Subject Alternative Name (SAN).
  static Future<SecurityContext> getSecurityContextForHost(String host) async {
    final cleanHost = host.trim().toLowerCase();
    if (_hostContextCache.containsKey(cleanHost)) {
      return _hostContextCache[cleanHost]!;
    }

    if (_inFlightGenerations.containsKey(cleanHost)) {
      return _inFlightGenerations[cleanHost]!;
    }

    final future = _generateSecurityContextForHost(cleanHost);
    _inFlightGenerations[cleanHost] = future;
    try {
      final context = await future;
      _hostContextCache[cleanHost] = context;
      return context;
    } finally {
      _inFlightGenerations.remove(cleanHost);
    }
  }

  static Future<SecurityContext> _generateSecurityContextForHost(String host) async {
    final openssl = await _findOpenssl();
    if (openssl == null) {
      return getSecurityContext();
    }

    try {
      final dir = await _getTempDir();
      final caCertPath = '${dir.path}/ca.crt';
      final caKeyPath = '${dir.path}/ca.key';
      final leafKeyPath = '${dir.path}/leaf.key';

      final hostSafe = host.replaceAll(RegExp(r'[^a-zA-Z0-9.-]'), '_');
      final csrPath = '${dir.path}/$hostSafe.csr';
      final extPath = '${dir.path}/$hostSafe.ext';
      final crtPath = '${dir.path}/$hostSafe.crt';

      final crtFile = File(crtPath);
      if (await crtFile.exists()) {
        final leafCertPem = await crtFile.readAsString();
        final context = SecurityContext();
        context.useCertificateChainBytes(utf8.encode('$leafCertPem\n$caCertificatePem'));
        context.usePrivateKeyBytes(utf8.encode(leafPrivateKeyPem));
        return context;
      }

      final isIp = InternetAddress.tryParse(host) != null;
      final san = isIp ? 'IP.1 = $host' : 'DNS.1 = $host\nDNS.2 = *.$host';

      final extContent = '''
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
$san
''';
      await File(extPath).writeAsString(extContent);

      // Generate CSR
      final reqRes = await Process.run(openssl, [
        'req',
        '-new',
        '-key',
        leafKeyPath,
        '-out',
        csrPath,
        '-subj',
        '/CN=$host',
      ]);
      if (reqRes.exitCode != 0) {
        stderr.writeln('ApiLab OpenSSL req error: ${reqRes.stderr}');
        return getSecurityContext();
      }

      // Sign certificate with CA
      final signRes = await Process.run(openssl, [
        'x509',
        '-req',
        '-in',
        csrPath,
        '-CA',
        caCertPath,
        '-CAkey',
        caKeyPath,
        '-CAcreateserial',
        '-out',
        crtPath,
        '-days',
        '365',
        '-sha256',
        '-extfile',
        extPath,
      ]);
      if (signRes.exitCode != 0) {
        stderr.writeln('ApiLab OpenSSL sign error: ${signRes.stderr}');
        return getSecurityContext();
      }

      final leafCertPem = await crtFile.readAsString();
      final context = SecurityContext();
      context.useCertificateChainBytes(utf8.encode('$leafCertPem\n$caCertificatePem'));
      context.usePrivateKeyBytes(utf8.encode(leafPrivateKeyPem));
      return context;
    } catch (e, stack) {
      stderr.writeln('ApiLab Cert generation exception: $e\n$stack');
      return getSecurityContext();
    }
  }

  static String getAndroidInstructions(String certPath) => '''
To trust ApiLab CA on Android:

1. Install CA Certificate on Android device / emulator:
   • Transfer '$certPath' to your device (via ADB or download).
     ADB command: adb push "$certPath" /sdcard/Download/apilab_ca.crt
   • Go to Settings -> Security (or "Security & Privacy" -> "More security settings").
   • Tap "Encryption & credentials" -> "Install a certificate" -> "CA certificate".
   • Tap "Install anyway" and select 'apilab_ca.crt'.

2. Configure your Android App (res/xml/network_security_config.xml):
   <?xml version="1.0" encoding="utf-8"?>
   <network-security-config>
       <base-config>
           <trust-anchors>
               <certificates src="system" />
               <certificates src="user" />
           </trust-anchors>
       </base-config>
   </network-security-config>

3. Reference it in AndroidManifest.xml (<application> tag):
   <application
       android:networkSecurityConfig="@xml/network_security_config"
       ...>

4. Set device Wi-Fi proxy:
   • Connect to the same Wi-Fi network as ApiLab.
   • In Wi-Fi Settings -> Advanced / Edit -> Proxy: Manual.
   • Host: [Your Local Wi-Fi IP shown in ApiLab header]
   • Port: 9888 (or your configured port).
''';

  static String getMacInstructions(String certPath) => '''
To trust ApiLab CA on macOS:
1. Double-click the exported 'apilab_ca.crt' file or run in Terminal:
   sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$certPath"
2. Open Keychain Access -> find "ApiLab Proxy CA" -> Always Trust.
''';

  static String getWindowsInstructions(String certPath) => '''
To trust ApiLab CA on Windows:
1. Open PowerShell as Administrator and run:
   certutil -addstore -f "ROOT" "$certPath"
2. Or double click 'apilab_ca.crt' -> Install Certificate -> Place in 'Trusted Root Certification Authorities'.
''';

  static String getLinuxInstructions(String certPath) => '''
To trust ApiLab CA on Linux (Ubuntu/Debian):
1. sudo cp "$certPath" /usr/local/share/ca-certificates/apilab_ca.crt
2. sudo update-ca-certificates
''';
}
