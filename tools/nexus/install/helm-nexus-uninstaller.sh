#Prerequisite, ocp connection opened ocp: oc login https://ocpmaster01.gfilab.es:8443/

#Delete proyect
#oc delete project nexus

#Delete the pod and all their dependecias. Less the pvc, sc and pv.
helm uninstall sonatype-nexus -n nexus
oc delete all --selector app=sonatype-nexus -n nexus

#Delete the pvc
oc delete pvc sonatype-nexus-pvc -n nexus

#Delete the sc
oc delete sc sonatype-nexus-sc

#Delete the pv
oc delete pv sonatype-nexus-pv