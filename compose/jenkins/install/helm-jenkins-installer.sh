#Prerequisite, ocp connection opened ocp: oc login https://ocpmaster01.gfilab.es:8443/
#Prerequisite, download the helm chart to the helm installer: https://www.jenkins.io/doc/book/installing/kubernetes/
#Prerequisite tiller manager operator for helm: https://github.com/jenkinsci/helm-charts/blob/main/charts/jenkins/README.md
helm repo add jenkinsci https://charts.jenkins.io
helm repo update
helm search repo jenkinsci
echo " Updated the helm jenkins repo was updated"

actived=$(oc describe project sjenkins | grep Active)
if [ -z "${actived}" ]; then
    oc create namespace sjenkins
	echo "The sjenkins namespace is created: ${actived}."
else
	echo "The sjenkins namespace already was created"
fi

#Create the pvc. Prerrequisite the disc path must monted, see jenkins-pv.
oc apply -f jenkins-sc.yaml
oc apply -f jenkins-pv.yaml
oc apply -f jenkins-pvc.yaml -n sjenkins

status=$(oc describe sc jenkins-sc | grep Status)
echo "Jenkins SC status ${status}"

status=$(oc describe pv jenkins-pv | grep Status)
echo "Jenkins PV status ${status}"

status=$(oc describe pvc jenkins-pvc -n sjenkins | grep Status)
echo "Jenkins PVC status ${status}"

oc apply -f jenkins-sa.yaml -n sjenkins

#Helm installer. EYE!!: with runAsUser and fsGroup (if the pod wasn't installed properlly, see the Pod Event) => $helm uninstall jenkins -n sjenkins, and adapt the values in jenkins-values.yaml.
echo "Start jenkins pod installation Helm"
helm install jenkins -n sjenkins -f jenkins-values.yaml jenkinsci/jenkins
echo "Helm installer success"

oc apply -f jenkins-tls-route.yaml -n sjenkins
echo "Secure route created"

#Get your 'admin' user password by running:
secret=$(oc get secret -n sjenkins jenkins -o jsonpath="{.data.jenkins-admin-password}")
secretDecodec=$(echo $secret | base64 --decode)
echo "Print initial credentials: ${secretDecodec}"

#oc serviceaccounts get-token jenkins -n sjenkins
sa-token=$(oc serviceaccounts get-token jenkins -n sjenkins)
echo "Print sa token: ${sa-token}"

#oc adm policy add-cluster-role-to-user view system:serviceaccount:sjenkins:jenkins
#oc adm policy add-cluster-role-to-user edit system:serviceaccount:sjenkins:jenkins
#To add the view role to the jenkins service account in the sjenkins project:
#oc policy add-role-to-user view system:serviceaccount:sjenkins:jenkins
#oc policy add-role-to-user edit system:serviceaccount:sjenkins:jenkins
#oc describe sa jenkins -n sjenkins
#oc describe role jenkins -n sjenkins

#To allow all service accounts in all projects to view resources in the sjenkins project:
#oc policy add-role-to-user view system:serviceaccount -n sjenkins
#To allow the jenkins service account in the sjenkins project to edit resources in the eda-prueba-dev project:
#oc policy add-role-to-user edit system:serviceaccount:sjenkins:jenkins -n eda-prueba-dev
echo "Create the RBACs to jenkins can deploy pods into the others namespaces"
read -n 1 -s -r -p "Press any key to window close..."
