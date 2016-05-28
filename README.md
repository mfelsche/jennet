# jennet
Jennet is an HTTP web framework written in Pony

## Features
- **Context:** Store data that can be used by the request handler as well as any middleware.

- **Middleware Chaining:** Easily add multiple middlewares to the route that can execute functions both before and after the request handler.

- **Explicit Route Matches:** A request can only match exactly one or no route so that there are no unintended matches.

- **Route Parameters:** Allow the router to parse the incoming URL path for you by specifying a route parameter. The router will then store a dynamic value in the context.

- **File Server:** Easily serve static files and set custom NotFound handlers

## Usage

### Named Parameters

```pony
actor Main
  new create(env: Env) =>
    let auth = try
      env.root as AmbientAuth
    else
      env.out.print("unable to use network.")
      return
    end
    let jennet = Jennet(auth, env.out, "8080")
    jennet.get("/", H)
    jennet.get("/:name", H)
    try
      (consume jennet).serve()
    else
      env.out.print("invalid routes.")
    end

class H is Handler
  fun val apply(c: Context, req: Payload): Context iso^ =>
    let res = Payload.response()
    let name = c.param("name")
    res.add_chunk("Hello")
    if name != "" then
      res.add_chunk(" " + name)
    end
    res.add_chunk("!")
    c.respond(consume req, consume res)
    consume c
```

As you can see, `:name` is a named parameter. The values are accessible via the Context. In this example :name can be retrieved by `c.param("name")`.

Named parameters only match a single path segment:
```
Path: /user/:username

 /user/jim                 match
 /user/greg                match
 /user/greg/info           no match
 /user/                    no match
```

The router uses a compact prefix tree algorithm (or [Radix Tree](https://en.wikipedia.org/wiki/Radix_tree)) since URL paths have a hierarchical structure and only make use of a limited set of characters (byte values). It is very likely that there are a lot of common prefixes, which allows us to easily match incoming URL paths.

see also: [julienschmidt/httprouter](https://github.com/julienschmidt/httprouter)

### Using Middleware

```pony
actor Main
  new create(env: Env) =>
    let auth = try
      env.root as AmbientAuth
    else
      env.out.print("unable to use network.")
      return
    end
    let users = recover Map[String, String](1) end
    users("my_username") = "my_super_secret_password"
    let middleware = recover val
      let mw = Array[Middleware](1)
      mw.push(BasicAuth("My Realm", consume users))
    end
    let jennet = Jennet(auth, env.out, "8080")
    jennet.get("/", H, middleware)
    try
      (consume jennet).serve()
    else
      env.out.print("invalid routes.")
    end

class H is Handler
  fun val apply(c: Context, req: Payload): Context iso^ =>
    let res = Payload.response()
    res.add_chunk("Hello!")
    c.respond(consume req, consume res)
    consume c
```

This example uses Basic Authentication (RFC 2617) with the included BasicAuth middleware.

### Serving Static Files

```pony
actor Main
  new create(env: Env) =>
    let auth = try
      env.root as AmbientAuth
    else
      env.out.print("unable to use network.")
      return
    end
    let jennet = Jennet(auth, env.out, "8080")
    jennet.serve_file(auth, "/", "/index.html")
    try
      (consume jennet).serve()
    else
      env.out.print("invalid routes.")
    end
```
