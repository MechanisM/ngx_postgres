# vi:filetype=perl

use lib 'lib';
use Test::Nginx::Socket;

repeat_each(2);

plan tests => repeat_each() * (blocks() * 3 - 2 * 1);

our $http_config = <<'_EOC_';
    upstream database {
        postgres_server     127.0.0.1:5432 dbname=ngx_test
                            user=ngx_test password=ngx_test;
    }
_EOC_

worker_connections(128);
run_tests();

no_diff();

__DATA__

=== TEST 1: authorized (auth basic)
--- http_config eval: $::http_config
--- config
    location = /auth {
        internal;
        postgres_escape     $user $remote_user;
        postgres_escape     $pass $remote_passwd;
        postgres_pass       database;
        postgres_query      "select login from users where login=$user and pass=$pass";
        postgres_rewrite    no_rows 403;
        postgres_set        $login 0 0 required;
        postgres_output     none;
    }

    location /test {
        auth_request        /auth;
        auth_request_set    $auth_user $login;
        echo -n             "hi, $auth_user!";
    }
--- more_headers
Authorization: Basic bmd4X3Rlc3Q6bmd4X3Rlc3Q=
--- request
GET /test
--- error_code: 200
--- response_headers
Content-Type: text/plain
--- response_body eval
"hi, ngx_test!"
--- timeout: 10



=== TEST 2: unauthorized (auth basic)
--- http_config eval: $::http_config
--- config
    location = /auth {
        internal;
        postgres_escape     $user $remote_user;
        postgres_escape     $pass $remote_passwd;
        postgres_pass       database;
        postgres_query      "select login from users where login=$user and pass=$pass";
        postgres_rewrite    no_rows 403;
        postgres_set        $login 0 0 required;
        postgres_output     none;
    }

    location /test {
        auth_request        /auth;
        auth_request_set    $auth_user $login;
        echo -n             "hi, $auth_user!";
    }
--- more_headers
Authorization: Basic bW9udHk6c29tZV9wYXNz
--- request
GET /test
--- error_code: 403
--- response_headers
Content-Type: text/html
--- timeout: 10



=== TEST 3: unauthorized (no authorization header)
--- http_config eval: $::http_config
--- config
    location = /auth {
        internal;
        postgres_escape     $user $remote_user;
        postgres_escape     $pass $remote_passwd;
        postgres_pass       database;
        postgres_query      "select login from users where login=$user and pass=$pass";
        postgres_rewrite    no_rows 403;
        postgres_set        $login 0 0 required;
        postgres_output     none;
    }

    location /test {
        auth_request        /auth;
        auth_request_set    $auth_user $login;
        echo -n             "hi, $auth_user!";
    }
--- request
GET /test
--- error_code: 403
--- response_headers
Content-Type: text/html
--- timeout: 10