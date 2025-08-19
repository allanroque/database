

```plain
[Usuários/CI/CD]
     |
   80/443
     v
+-----------------------+
|  AAP Controllers      |----5432/TCP---->[PostgreSQL Externo]
|  (cluster 3 nós)      |
+-----------------------+
     |\
     | \______________________________ SSH 22 / WinRM 5986 _____________________________
     |                                   (execução remota direta)
     |                     |--------------------|--------------------|-----------------|
     v                     v                    v                    v                 v
[Servers - On-prem A]  [Servers - On-prem B] [Servers - AWS]    [Servers - Azure]  [Servers - OCI]
