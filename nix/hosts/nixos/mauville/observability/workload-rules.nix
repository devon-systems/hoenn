_: {
  flake.nixosModules.mauville = _: {
    services.prometheus.rules = [
      (builtins.toJSON {
        groups = [
          {
            name = "hoenn-workload-ownership";
            interval = "30s";
            rules = [
              {
                record = "pod_workload_info";
                # ReplicaSet owners resolve to Deployments. Other pods retain their
                # controlling owner, and standalone pods use their own name.
                expr = ''
                  max by (cluster, namespace, pod, workload, workload_kind, node) (
                    (
                      label_replace(label_replace(
                        kube_pod_owner{job="kube-state-metrics",owner_kind="ReplicaSet",owner_is_controller="true"},
                        "replicaset", "$1", "owner_name", "(.*)"),
                        "workload_kind", "Deployment", "owner_kind", ".*")
                      * on (cluster, namespace, replicaset) group_left(workload)
                      label_replace(kube_replicaset_owner{job="kube-state-metrics",owner_kind="Deployment",owner_is_controller="true"},
                        "workload", "$1", "owner_name", "(.*)")
                      or
                      label_replace(label_replace(
                        kube_pod_owner{job="kube-state-metrics",owner_kind!="ReplicaSet",owner_is_controller="true"},
                        "workload", "$1", "owner_name", "(.*)"),
                        "workload_kind", "$1", "owner_kind", "(.*)")
                      or
                      label_replace(label_replace(
                        kube_pod_info{job="kube-state-metrics",created_by_kind=""},
                        "workload", "$1", "pod", "(.*)"),
                        "workload_kind", "Pod", "pod", ".*")
                    )
                    * on (cluster, namespace, pod) group_left(node)
                    max by (cluster, namespace, pod, node) (kube_pod_info{job="kube-state-metrics"})
                  )
                '';
              }
            ];
          }
        ];
      })
    ];
  };
}
