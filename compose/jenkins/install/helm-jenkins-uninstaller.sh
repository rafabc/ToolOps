#Prerequisite, ocp connection opened ocp: oc login https://ocpmaster01.gfilab.es:8443/

#Delete proyect
#oc delete project jenkins

#Delete the pod and all their dependecias. Less the pvc, sc and pv.
helm uninstall jenkins -n jenkins
oc delete all --selector app=jenkins -n jenkins

#Delete the pvc
oc delete pvc jenkins-pvc -n jenkins

#Delete the sc
oc delete sc jenkins-sc

#Delete the pv
oc delete pv jenkins-pv