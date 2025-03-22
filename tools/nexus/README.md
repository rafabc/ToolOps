# SONATYPE_NEXUS #

## Installation and uninstallation in kubernetes platform (OCP)

Its based on the [Helm Project](https://v2.helm.sh/docs/install/) and deployed in [Helm OCP platform](https://www.openshift.com/blog/getting-started-helm-openshift). The Helm charts involved are located in the git repository [helm
/charts](https://github.com/helm/charts/tree/master/stable/sonatype-nexus) and [Oteemo
/charts](https://github.com/Oteemo/charts/tree/master/charts/sonatype-nexus). The Nexus instance will be deployed in the namespace: nexus.

- [installer.sh](install/helm-nexus-installer.sh).
- [uninstaller.sh](install/helm-nexus-uninstaller.sh).
-------------

## Configuration


-------------
