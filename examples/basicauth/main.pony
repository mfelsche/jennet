use "net"
use "collections"
use "http_server"
use "../../jennet"

actor Main
  new create(env: Env) =>
    let tcplauth: TCPListenAuth = TCPListenAuth(env.root)

    let handler =
      {(ctx: Context): Context iso^ =>
        ctx.respond(
          StatusResponse(
            StatusOK,
            [("Content-Length", "6")]
          ),
          "Hello!".array()
        )
        consume ctx
      }

    let users = recover Map[String, String](1) end
    users("my_username") = "my_super_secret_password"
    let authenticator = BasicAuth("My Realm", consume users)

    let server =
      Jennet(tcplauth, env.out)
        .> get("/", handler, [authenticator])
        .serve(ServerConfig(where port' = "8080"))

    if server is None then env.out.print("bad routes!") end
