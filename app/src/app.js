// load modules
const config = require("config");
const logger = require("logger");
const koa = require("koa");
const cors = require("@koa/cors");
const koaLogger = require("koa-logger");
const loader = require("loader");
const validate = require("koa-validate");
const ErrorSerializer = require("serializers/errorSerializer");
const convert = require("koa-convert");
const koaSimpleHealthCheck = require("koa-simple-healthcheck");
const Sentry = require('@sentry/node');

// instance of koa
const app = koa();

Sentry.init({ dsn: "https://a8b99d861b264fa68a8985f3f8508c00@o163691.ingest.sentry.io/6262197" });

app.on("error", (err, ctx) => {
  Sentry.withScope(function(scope) {
    scope.addEventProcessor(function(event) {
      return Sentry.Handlers.parseRequest(event, ctx.request);
    });
    Sentry.captureException(err);
  });
});

// if environment is dev then load koa-logger
if (process.env.NODE_ENV === "dev") {
  logger.debug("Use logger");
  app.use(koaLogger());
}

app.use(function* handleErrors(next) {
  try {
    yield next;
  } catch (inErr) {
    let error = inErr;
    try {
      error = JSON.parse(inErr);
    } catch (e) {
      logger.debug("Could not parse error message - is it JSON?: ", inErr);
      error = inErr;
    }
    this.status = error.status || this.status || 500;
    if (this.status >= 500) {
      logger.error(error);
    } else {
      logger.info(error);
    }

    this.body = ErrorSerializer.serializeError(this.status, error.message);
    if (process.env.NODE_ENV === "prod" && this.status === 500) {
      this.body = "Unexpected error";
    }
  }
  this.response.type = "application/vnd.api+json";
});

// load custom validator
app.use(validate());

app.use(convert.back(cors()));

app.use(
  convert.back(
    koaSimpleHealthCheck({
      path: "/v1/fw_mail/healthcheck"
    })
  )
);

// load routes
loader.loadQueues(app);

// Instance of http module
const appServer = require("http").Server(app.callback());

// get port of environment, if not exist obtain of the config.
// In production environment, the port must be declared in environment variable
const port = config.get("service.port");

const server = appServer.listen(port, () => {});

logger.info(`Server started in port:${port}`);

module.exports = server;
