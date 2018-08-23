/*
# Licensed Materials - Property of IBM
#
# (C) Copyright IBM Corp. 2017 All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplicate or
# disclosure restricted by GSA ADP Schedule Contract with
# IBM Corp.
# encoding: utf-8
*/

package e2e

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	//commontest "github.ibm.com/alchemy-containers/armada-storage-e2e/common"
	"bytes"
	"fmt"
	"github.ibm.com/alchemy-containers/armada-storage-e2e/framework"
	clientset "k8s.io/client-go/kubernetes"
	"k8s.io/client-go/pkg/api/v1"
	"os"
	"os/exec"
	"strings"
        "bufio"
)

var 
(

volumeid = ""
 pvname = ""
 clusterName = ""
 pvfilepath = ""
 pv *v1.PersistentVolume
 e2epath =  "src/github.ibm.com/alchemy-containers/armada-storage-e2e/e2e-tests/"
 pvscriptpath = ""
 ymlscriptpath = ""
 ymlgenpath  =  ""

)
var _ = framework.KubeDescribe("[Feature:PortWorxE2E]", func() {
	f := framework.NewDefaultFramework("armada-portworx")
	// filled in BeforeEach
	var c clientset.Interface
	var ns string

	BeforeEach(func() {
		c = f.ClientSet
		ns = f.Namespace.Name
                pvscriptpath = e2epath  +  "utilscript.sh"
                ymlscriptpath = e2epath + "mkpvyaml"
                ymlgenpath = e2epath + "yamlgen.yaml"
	})

	framework.KubeDescribe("PortWorx E2E ", func() {
		It("Port Worx E2e Testcases", func() {
			By("Volume Creation")
			gopath := os.Getenv("GOPATH")
                        clusterName, err :=  getCluster(gopath +  "/" + ymlgenpath)
			Expect(err).NotTo(HaveOccurred())
			pvfilepath = gopath + e2epath + "/pv-" + clusterName  + ".yaml" 
			filestatus, err := fileExists(pvfilepath)
			if filestatus == true {
				os.Remove(pvfilepath)
			}
			ymlscriptpath = gopath + "/" + ymlscriptpath
			cmd := exec.Command(ymlscriptpath)
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			By("Volume Creation1")
			cmd.Run()

			filestatus, err = fileExists(pvfilepath)
			Expect(err).NotTo(HaveOccurred())

			/* Static PV Creation */

			By("Static PV  Creation")
			if filestatus == true {
				pvscriptpath = gopath + "/" + pvscriptpath
                                filepatharg := fmt.Sprintf("%s", pvfilepath) 
				cmd := exec.Command(pvscriptpath, filepatharg, "pvcreate")
				var stdout, stderr bytes.Buffer
				cmd.Stdout = &stdout
				cmd.Stderr = &stderr
				err := cmd.Run()
				Expect(err).NotTo(HaveOccurred())
				outStr, _ := string(stdout.Bytes()), string(stderr.Bytes())
				pvstring := strings.Split(outStr, "/")
				pvnamestring := strings.Split(pvstring[1], " ")
                                pvname = pvnamestring[0]
				pv, err = c.Core().PersistentVolumes().Get(pvname)
				Expect(err).NotTo(HaveOccurred())

				Expect(pv.ObjectMeta.Annotations["ibm.io/dm"]).To(Equal("/dev/dm-0"))
				Expect(pv.ObjectMeta.Annotations["ibm.io/attachstatus"]).To(Equal("success")) 
			}

			/* Static PV deletion */

			By("Static PV  ")
			volumeid = pv.ObjectMeta.Annotations["ibm.io/volID"]
	                fmt.Printf("volumeid:\n%s%s\n", volumeid)
			err = c.Core().PersistentVolumes().Delete(pvname, nil)
			Expect(err).NotTo(HaveOccurred())
                        filestatus, err = fileExists(pvfilepath)
                        if filestatus == true {
                               os.Remove(pvfilepath)
                        }


                        /* Volume Deletion */

                         volidarg := fmt.Sprintf("%s", volumeid) 
	                 cmd = exec.Command(pvscriptpath, volidarg, "voldelete")
			 var stdout, stderr bytes.Buffer
		         cmd.Stdout = &stdout
			 cmd.Stderr = &stderr
		         err = cmd.Run()
			 Expect(err).NotTo(HaveOccurred())
			 outStr, errStr := string(stdout.Bytes()), string(stderr.Bytes())
			 fmt.Printf("out:\n%s\nerr:\n%s\n", outStr, errStr)


		})
	})
})

func fileExists(filename string) (bool, error) {
	if _, err := os.Stat(filename); err != nil {
		if os.IsNotExist(err) {
			return false, err
		}
	}
	return true, nil
}

func getCluster(filename string) (string, error) {

   var line = ""
   var clustername = ""

   file, err := os.Open(filename)
    if err != nil {
          return "",err
     }
    defer file.Close()
    scanner := bufio.NewScanner(file)
    for scanner.Scan() {
        line = scanner.Text()
        value := strings.Split(line, ":")
        if  value[0] ==  "cluster" {
               clustername = value[1]
               break
     }
    
}
     return clustername,nil
}
 

