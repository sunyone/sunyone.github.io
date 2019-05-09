# module 7

![0735](./images/sap-student-guide-0735.png)

Remote Desktop Protocol (RDP): Users who access Windows Terminal Services in the public cloud usually use the Microsoft Remote Desktop Protocol.

By default, RDP connections establish an underlying SSL/TLS connection. 

![0736](./images/sap-student-guide-0736.png)

Secure Shell (SSH): SSH is the preferred approach for establishing administrative connections to Linux servers.

SSH is a protocol that, like SSL, provides a secure communications channel between the client and the server.

SSH supports tunneling for running applications (such as X-Windows) on top of SSH to protect the application session in transit.

![0737](./images/sap-student-guide-0737.png)

Database server traffic: If clients or servers need to access databases in the cloud, they might need to traverse the internet as well.

![0738](./images/sap-student-guide-0738.png)

The AWS Management Console uses SSL/TLS between the client browser and console service endpoints to protect AWS service management traffic. Traffic is encrypted, data integrity is authenticated, and the client browser authenticates the identity of the console service endpoint by using an X.509 certificate.

After an SSL/TLS session is established between the client browser and the console service endpoint, subsequent HTTP traffic is protected within the SSL/TLS session.

Alternatively, use AWS APIs to manage services from AWS either directly from applications or third-party tools, or via SDKs, or via AWS command line tools.

AWS APIs are web services (SOAP or REST) over HTTPS. SSL/TLS sessions are established between the client and the specific AWS service endpoint, depending on the APIs used, and all subsequent traffic, including the SOAP/REST envelope and user payload, is protected within the SSL/TLS session.

![0739](./images/sap-student-guide-0739.png)

The slide lists a few commonly practiced techniques to protect data in transit.

![0740](./images/sap-student-guide-0740.png)

For more information about AWS Certificate Manager, see <https://aws.amazon.com/certificate-manager/>.