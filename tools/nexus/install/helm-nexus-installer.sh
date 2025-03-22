#Prerequisite, ocp connection opened ocp: oc login https://ocpmaster01.gfilab.es:8443/
#Prerequisite, download the helm chart to the helm installer: https://sonatype.github.io/helm3-charts/
#Prerequisite tiller manager operator for helm: https://github.com/Oteemo/charts/tree/master/charts/sonatype-nexus.md
helm repo add oteemocharts https://oteemo.github.io/charts
helm repo update
helm search repo oteemocharts
echo " Updated the helm sonatype repo was updated"

actived=$(oc describe project jenkins | grep Active)
if [ -z "${actived}" ]; then
    oc create namespace jenkins
	echo "The jenkins namespace is created: ${actived}."
else
	echo "The jenkins namespace already was created"
fi

#Create the pvc. Prerrequisite the disc path must monted, see nexus-pv.
oc apply -f nexus-sc.yaml
oc apply -f nexus-pv.yaml
oc apply -f nexus-pvc.yaml -n jenkins

status=$(oc describe sc sonatype-nexus-sc | grep Status)
echo "Nexus SC status ${status}"

status=$(oc describe pv sonatype-nexus-pv | grep Status)
echo "Nexus PV status ${status}"

status=$(oc describe pvc sonatype-nexus-pvc -n jenkins | grep Status)
echo "Nexus PVC status ${status}"


read -n 1 -s -r -p "Press any key to continue..."

#Helm installer. EYE!!: with runAsUser and fsGroup (if the pod wasn't installed properlly, see the Pod Event) => $helm uninstall sonatype-nexus -n jenkins, and adapt the values in sonatype-values.yaml.
#To degug teh installation: 
helm install sonatype-nexus --dry-run --debug -f sonatype-values.yaml ./
read -n 1 -s -r -p "Press any key to continue Nexus intallation..."

echo "Start jenkins pod installation Helm"
helm install sonatype-nexus -n jenkins -f sonatype-values.yaml oteemocharts/sonatype-nexus
echo "Helm installer success"

oc apply -f nexus-tls-route.yaml -n jenkins
echo "Secure route created"

#Get your 'admin' user password by running:
secret=$(oc get secret -n jenkins sonatype-nexus -o jsonpath="{.data.jenkins-admin-password}")
secretDecodec=$(echo $secret | base64 --decode)
echo "Print initial credentials: ${secretDecodec}"

#
sa-token=$(oc serviceaccounts get-token sonatype-nexus -n jenkins)
echo "Print sa token: ${sa-token}"

read -n 1 -s -r -p "Press any key to window close..."
