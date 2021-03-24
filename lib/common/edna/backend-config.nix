{
  api = {
    listen-addr = "*:9000";
    serve-docs = false;
  };
  db = {
    conn-string = "host=postgres dbname=edna user=postgres password=12345";
    max-connections = 200;
    initialisation = {
      mode = "enable";
      init-script = "/init.sql";
    };
  };
}
