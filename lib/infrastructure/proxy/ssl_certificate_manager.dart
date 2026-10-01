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

  static SecurityContext getSecurityContext() {
    final context = SecurityContext();
    context.useCertificateChainBytes(utf8.encode(caCertificatePem));
    context.usePrivateKeyBytes(utf8.encode(caPrivateKeyPem));
    return context;
  }

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
