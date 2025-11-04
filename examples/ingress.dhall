let Prelude =
      ../Prelude.dhall
        sha256:931cbfae9d746c4611b07633ab1e547637ab4ba138b16bf65ef1b9ad66a60b7f

let map = Prelude.List.map

let kubernetes =
      ../package.dhall
        sha256:1a0d599eabb9dd154957edc59bb8766ea59b4a245ae45bdd55450654c12814b0

let Service = { name : Text, host : Text, version : Text }

let services = [ { name = "foo", host = "foo.example.com", version = "2.3" } ]

let makeTLS
    : Service → kubernetes.IngressTLS.Type
    = λ(service : Service) →
        { hosts = Some [ service.host ]
        , secretName = Some "${service.name}-certificate"
        }

let makeRule
    : Service → kubernetes.IngressRule.Type
    = λ(service : Service) →
        { host = Some service.host
        , http = Some
          { paths =
            [ kubernetes.HTTPIngressPath::{
              , backend = kubernetes.IngressBackend::{
                , service = Some kubernetes.IngressServiceBackend::{
                  , name = service.name
                  , port = Some kubernetes.ServiceBackendPort::{
                    , number = Some 80
                    }
                  }
                }
              , pathType = "Exact"
              }
            ]
          }
        }

let mkIngress
    : List Service → kubernetes.Ingress.Type
    = λ(inputServices : List Service) →
        let annotations =
              toMap
                { `kubernetes.io/ingress.class` = "nginx"
                , `kubernetes.io/ingress.allow-http` = "false"
                }

        let defaultService =
              { name = "default"
              , host = "default.example.com"
              , version = " 1.0"
              }

        let ingressServices = inputServices # [ defaultService ]

        let spec =
              kubernetes.IngressSpec::{
              , tls = Some
                  ( map
                      Service
                      kubernetes.IngressTLS.Type
                      makeTLS
                      ingressServices
                  )
              , rules = Some
                  ( map
                      Service
                      kubernetes.IngressRule.Type
                      makeRule
                      ingressServices
                  )
              }

        in  kubernetes.Ingress::{
            , metadata = kubernetes.ObjectMeta::{
              , name = Some "nginx"
              , annotations = Some annotations
              }
            , spec = Some spec
            }

in  mkIngress services
