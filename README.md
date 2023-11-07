# Geolocator - Vio.com coding challenge

(For the full description of the challenge check [here](./docs/challenge.md))

The challenge is split into 2 parts:

## Location module (`geolocation`)

The main features of this module are:

- Owns the `location` entity/schema and the access to the DB (I have chosen Postgres w/ ecto)
- Has a CSV loader used to populate the database with a given file
  - The load process generates statistics that are returned at the end of the process

### Setting up the module

#### Pre-requirements

* Elixir
* Erlang
* Docker (and docker compose)

I have included a `.tool-versions` file so we can use `asdf install` and install the dependencies automatically (See [asdf](https://asdf-vm.com/))

Docker can be found [here](https://www.docker.com/)

#### Compiling the module

Once elixir and erlang are installed, we can compile the module with

```bash
mix deps.get
mix compile
```

This will compile the module using `MIX_ENV=dev` which is enough for using the CSV loader functionality

#### Setting up the database and its migrations

Since we need a running database with a valid table in order to load the locations into it, we need to start an instance
of Postgres. I've configured a docker compose file to help doing that in a local dev enviroment. In order to start the DB just type

```
docker compose up db 
```

The DB files are stored at `./postgres_data` so you can stop the service and delete the folder to start from scratch.

Once the DB is running, we need to run the migrations in order to create the database and the `locations` table. We can set up everything by running the following:

```bash
mix ecto.setup
```

Once mix gives us the ok, the database will be ready for importing the CSV.

### Loading a CSV file

In order to not require using `iex` and calling `Geolocator.Loader` directly, I've created a `Mix Task` that will do so for us.

```bash
  LOADER_BATCH_SIZE=2500 mix geolocator.loader -f <file_path>
```

The `LOADER_BATCH_SIZE` can be any number between 1 and 9362, this last number being due to ecto/postgres limit of 65535 parameters in a query and since the `location` schema has 7 parameters per row, we can only fit 9362 rows per insert. The environment variable can also be ommited and will default to 2000 rows
per insert.

I've performed some preliminary benchmarking to decide on the batch size and it doesn't seem to affect the process too much:

| Batch size       | Run 1 ms                  | Run 2 ms     | Run 3 ms     |
| ---------------- | ------------------------- | ------------ | ------------ |
| 1                | Cancelled it after 5 mins |              |              |
| 500              | 38217631                  | 43317925     | 41711280     |
| 900<sup>1</sup>  | 40358881                  | 41050354     | 40085983     |
| __2000__         | __37804438__              | __37651701__ | __37803080__ |
| 5000             | 38389044                  | 43081773     | 43060038     |
| 9362<sup>2</sup> | 45540493                  | 39264909     | 45297188     |

As we can see the fastest load times seem to happen around the 2000 batch size. Some other value have been chosen because
they seemed relevant:

- <sup>1</sup>: The file buffer is set to be 100,000 bytes and with rows being around 100 characters, it means it can fit about
1000 rows, so I went to slightly less in order to try to fit a whole batch in the buffer.

- <sup>2</sup>: As previously mentioned, the max number of rows allowed by Postgres/ecto due to parameter limits in queries. This number will change if more columns are added to (or removed from) the `locations` schema. 

### Other decision choices

Instead of creating a whole separate mix project, I decided to combine this component and the web server
in the same component. This is due to the way phoenix naturally splits the http server and service layers into
different modules. It seemed a little redundant to create a mix project with all the code and then a phoenix
project with just a 5 line controller and the dependency to the module. I could have used an umbrella project to make the separation of concerns/owneship more apparent, but it still seemed like complexity for the sake of complexity.

In a real world scenario, if the geolocation library were to be used by multiple services, it could make sense to have it
extracted from this repo (and it would be quite trivial to do so) but still, there would be a number of questions to answer like who owns the database; e.g: it is a good (or at least common) practice for a database to have a single owner/service,  how/when to run the DB migrations, etc

The `stats` struct is as simple as I could make it and still make sense. 

Also regarding the `stats` the `&load_row/2` in the loader returns some simple counters (accepted and discarded rows) instead of a `stats` object of its own for the sake of simplicity, but if the stats were to be more complex, it would make sense for the whole load pipeline to have access to a `stats` object and pass it around each stage while filling it.

Lastly, regarding what to do when conflicts happen (a conflict being two or more rows with the same ip address), I've decided to take the last occurence as the truth, as I expect that to be the correct behaviour in the case of some other 
service/process appending to the file the most up to date information. This also has the benefit of being really easy to 
code, as it only requires transforming the insert operation into an upsert one. If we wanted to do the opposite (only accept 
the first occurence) we can just change the inserts's `on_conflict` config so it rejects conflicts, meaning it will only 
allow the insert the first time. If we just don't want to insert rows with any conflict at all, it would require us to 
either load the whole file in memory (not really an option for really huge files) or read it twice, first to pre-process it 
and second to actually load it. The pre-processing would mean building a map with ip_addresses of conflicting ips and then 
use that in the second pass to ignore rows with an ip in the map, but a this point it would be a better idea to just process 
the file outside elixir, for example directly in the filesystem using any of the tools provided by the os (for example with 
something like `awk`)


### Improvements

There are some improvements that could be done in a real world scenario as the project growns:

Add more metrics to the `stats` object, for example subcategories for discarded rows; where they discarded during CSV parse, while checking the changeset or at the insert itself? This would also require passing a `stats` object around the load pipeline as previously mentioned.

Separate the repository layer form the service one via a ports-adapter, dependency inyection pattern or something similar. I didn't think it necessary just yet because we are only using a single storage backend and for testing we can use Ecto's Sandbox adapter (although you could argue that by using it any test we write cannot be considered a unit test at all)


## HTTP Server (`geolocation_web`)

### Setting up the system

There are 2 ways of running the service; locally using a console or having it deploy in a docker container.

#### Locally

Usefull we you are activelly working witht the codebase and want to test the changes fast. This requires having both
`elixir` and `erlang` installed as described in the [pre-requirements](#pre-requirements) section.

First get the dependencies with

```bash 
mix deps.get
```

And the either launch the phoenix server by itself or inside an interactive terminal

```bash
# Standalone phoenix server
mix phx.server
```

```bash
# This will open a iex terminal with Phoenix running on it
iex -S mix phx.server
```

Take into account that since we are not specifying the MIX_ENV, by default it will be set to `dev`, so the configuration
file it will use will be `dev.exs` (plus `runtime.exs`, but other than `LOADER_BATCH_SIZE` all other properties will only
be used in the `prod` enviroment)


#### Inside a container using docker compose

This is the most convenient way of deploying the service if we want to either simulate the production enviroment or we don't
even want to install elixir/erlang to run the service. We only need to have docker installed and running (check [pre-requirements](#pre-requirements) section).

First we will ask docker compose to build an image with the phoenix release

```bash
docker compose build
```

This will use a build image with all the required dependencies to generate a release of the phoenix service and then
copy the release inside a much more lightweight image that will be used as the deploy image (check the [Dockerfile](./Dockerfile) for details)

After the deploy image has been, depending if the database container is already running we can either start just the phoenix service or both the service and the database:

```bash
# This will start both the database and the phoenix service (phoenix will wait for Postgres)
docker compose up
```

```bash
# This will just start the phoenix service. If the database is not running it will crash on boot
docker compose up geolocator
```

In both cases, the phoenix service will attempt run any pending database migrations (stored in [priv/repo/migrations](./priv/repo/migrations/))

#### API Specs

There is just a single endpoint in the API, a `GET` request to `/api/locations/<IP_ADDRESS>` where <IP_ADDRESS> is the ip address we want to obtain the location info for. Of course, in order for this endpoint to return anything other than a 404, we need to have previously loaded the database (see [Loading a CSV file](#loading-a-csv-file)).

##### Ok example

Request:

```curl
curl --location 'http://localhost:4000/api/locations/35.227.116.242'
```

Returns a 200 with the body:

```json
{
    "city": "Port Simoneside",
    "country": "Uganda",
    "country_code": "LR",
    "ip_address": "35.227.116.242",
    "latitude": 27.028236306590998,
    "longitude": -86.40283568649986,
    "mystery_value": 3227619485
}
```

##### Error example

The API returns a 404 when there is no match in the database:

```curl
curl --location 'http://localhost:4000/api/locations/192.168.1.1'
```

Returns a 404 with the body:

```json
{
    "errors": {
        "detail": "Not Found"
    }
}
```

The API returns a 400 when the path param provided is not a valid ip address


```curl
curl --location 'http://localhost:4000/api/locations/a'
```

Returns a 404 with the body:

```json
{
    "errors": {
        "detail": "Bad Request"
    }
}
```

#### Improvements

If the API where to grow in the future, it would be a good idea to add Swagger/OpenAPI specs for example using
the [open_api_spex](https://github.com/open-api-spex/open_api_spex) library.

Also either create our own metrics and/or reuse the one autogenerated by phoenix in [telemetry.ex](./lib/geolocator_web/telemetry.ex) (although to be fair I haven't really used them ever so I am not sure if they can be sent to an external
metrics storage like prometheus or they can only be consumed by the Phoenix.LiveDashboard)

### Adding a scheduled task for running the CSV loader

We can use [quantum](https://hexdocs.pm/quantum/3.5.0/readme.html) in order to call functions with a cron-like syntax. That 
way we can call `Geolocator.Loader.load_from_csv` with any given path. The only problem would be what to do with already loaded files, should we rename them, delete them or are they appended and we need to keep an ofset.

We would need to start a scheduller in the supervision tree of the application and then just configure it.

The config to enable a daily load would be something like (in `prod.exs`):

```elixir
config :geolocator, Geolocator.Scheduler,
  jobs: [
    {"@daily", {Geolocator.Loader, :load_from_csv, ["path/to/file"]}}
  ]
```