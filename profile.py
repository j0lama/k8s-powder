#!/usr/bin/env python

kube_description= "Phobos Powder profile"
kube_instruction= "To be done"

#
# Standard geni-lib/portal libraries
#
import geni.portal as portal
import geni.rspec.pg as PG
import geni.rspec.igext as IG


pc = portal.Context()
rspec = PG.Request()


# Profile parameters.
pc.defineParameter("computeNodeCount", "Number of Kubernetes nodes",
                   portal.ParameterType.INTEGER, 1)
pc.defineParameter("Hardware", "Node Hardware",
                   portal.ParameterType.STRING,"d430",[("d430","d430"),("d710","d710"), ("d820", "d820"), ("pc3000", "pc3000")])

params = pc.bindParameters()

#
# Give the library a chance to return nice JSON-formatted exception(s) and/or
# warnings; this might sys.exit().
#
pc.verifyParameters()



tour = IG.Tour()
tour.Description(IG.Tour.TEXT,kube_description)
tour.Instructions(IG.Tour.MARKDOWN,kube_instruction)
rspec.addTour(tour)

# Network
netmask="255.255.255.0"
network = rspec.Link("Network")
network.link_multiplexing = True
network.vlan_tagging = True
network.best_effort = True


# K8s Master
kube_m = rspec.RawPC("master")
kube_m.hardware_type = params.Hardware
kube_m.routable_control_ip = True
kube_m.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
kube_m.Site('Kubernetes')
iface = kube_m.addInterface()
iface.addAddress(PG.IPv4Address("192.168.1.1", netmask))
network.addInterface(iface)
kube_m.addService(PG.Execute(shell="bash", command="/local/repository/scripts/master.sh"))

# Nervion Slaves
for i in range(0,params.computeNodeCount):
    kube_s = rspec.RawPC('slave'+str(i))
    kube_s.hardware_type = params.Hardware
    kube_s.routable_control_ip = True
    kube_s.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU18-64-STD'
    kube_s.Site('Kubernetes')
    iface = kube_s.addInterface()
    iface.addAddress(PG.IPv4Address("192.168.1." + str(i+2), netmask))
    network.addInterface(iface)
    kube_s.addService(PG.Execute(shell="bash", command="/local/repository/scripts/slave.sh"))


#
# Print and go!
#
pc.printRequestRSpec(rspec)