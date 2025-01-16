**This is the step-by-step guide to authenticate NIFI with AZURE (OIDC Protocol)**

  This is the Guide to running NIFI on the local desktop. **( Next Readme.Md file will be pushed to the same repository which contains Instructions to deploy NIFI on Kubernetes and another customization... )**

  After configuring and following the below steps you will get the 2 NIFI node clusters and access the cluster on **https://localhost:8443** on your local desktop

  
## prerequisite
    1. Install Docker Desktop in the system
    2. Install git-cli in the system

**Guide**

open git cli
## Step 1

```
mkdir NIFI-OIDC
cd NIFI-OIDC
git clone https://github.com/sourabh748/OIDC-WITH-AZURE-END-TO-END-SOLUTION.git
cd OIDC-WITH-AZURE-END-TO-END-SOLUTION/certs
openssl req -x509 \
            -sha256 \
            -days 365 \
            -nodes \
            -newkey rsa:2048 \
            -subj "/C=IN/ST=TELANGANA/L=HYD/O=NIFI/OU=NIFI/CN=NIFI" \
            -keyout rootCA.key -out rootCA.pem
```

## Step 2

1. create an app registration in Azure
2. Go to the **API permission** ( APP registration [choose App Registration] --> Manage --> API Permission ) and Add permissions:-
     1. Group.Read.All
     2. User.Read.All

    **(Require Admin Consent On API permission On Above Permission & Permission Type should be Delegate)**
3. Create a group on Azure ( ex:- NIFI-ADMIN-GROUP )
4. Go to the **Token Configuration** ( APP registration [choose App Registration] --> Manage --> Token Configuration ):-
   
     Add optional claims:-
     1. upn
     2. email ( for on-prem AADS )
5. Go to **Authentication** ( APP registration [choose App Registration] --> Manage --> Authentication ):-
     1. ```+ Add Platform ``` --> ```web``` --> ```Add Redirect URI as https://localhost:8443/nifi-api/access/oidc/callback``` --> ```Configure```

## step 3

edit **.nifi1.env** && **.nifi2.env** & set the Environment variable properties below:-

| properties | default value | pattern (or description) |
|:----------:|:-------------:|:-------:|
|NIFI_OIDC_DISCOVERY_URL | ------- | https://login.microsoftonline.com/${MICROSOFT_TENANT_ID}/v2.0/.well-know/openid-configuration |
|MICROSOFT_TENANT_ID | ------ | Tenant Id |
|INITIAL_ADMIN_IDENTITY_EMAIL| ------- | Add your **upn** or **email** |
|MICROSOFT_APP_REGISTRATION_OBJECT_ID| -------- | your Application **spn Application Id** |
|MICROSOFT_APP_CLIENT_SECRET| ------- | Add your **spn secrets** |
|MICROSOFT_GROUP_FILTER| ------- | Add your group (ex:- NIFI-ADMIN) |

## step 4

```
cd OIDC-WITH-AZURE-END-TO-END-SOLUTION/compose
docker compose up --build
```
