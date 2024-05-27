import std.string;
import std.stdio;
import std.json;

import vibe.d;
import vibe.http.form;
import mysql.d;
import yaml;

import utils;

Mysql mysql_conn;



shared static this()
{
    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];

    yaml.Node db_config = Loader("./config.yml").load();

    mysql_conn = new Mysql(
      db_config["host"].as!string,
      db_config["username"].as!string,
      db_config["passoword"].as!string,
      db_config["database"].as!string
    );

    auto router = new URLRouter;
    router.get("/", &index);
    router.get("*", serveStaticFiles("public/"));

    listenHTTP(settings, router);

    logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}

void index(HTTPServerRequest req, HTTPServerResponse res)
{

    auto base_sql = "select * from bike_factories order by ";

    auto allowed_columns = ["name", "url", "description"];

    string order_column_sql = "id";
    if ("sort_by" in req.query) {
        if (req.query["sort_by"].inArray(allowed_columns)) {
            order_column_sql = mysql_conn.escape(req.query["sort_by"]);
        } else {
            logInfo(
                format("Unknown 'sort' argument \"%s\", allowed are %s", req.query["sort_by"], allowed_columns).color("red")
            );
        }
    }

    if ("direction" in req.query) {
        if (req.query["direction"].inArray(["asc", "desc"])) {
            order_column_sql ~= " " ~ mysql_conn.escape(req.query["direction"]);
        } else {
            logInfo(
                format("Unknown 'direction' argument \"%s\", allowed are %s", req.query["direction"], ["asc", "desc"]).color("red")
            );
        }
    }

    logInfo("SQL: " ~ (base_sql ~ order_column_sql).color("green"));

    auto q_res = mysql_conn.query(base_sql ~ order_column_sql);

    res.render!("index.dt", q_res, req);

}