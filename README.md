## About
The GenericAPIWrapper can be used to simplify calls to REST API's. This can be configured as a singleton that includes authentication details for example.

This will not cover every API, but it will hopefully be useable for the majority.

## Basic Usage
You need to create an instance of the genericAPIWrapper.cfc. This can be treated as a singleton object in application scope or using your favourite factory service such as WireBox or similar.

```
api = new genericAPIWrapper( [settings] );
```

### Settings
* `settings` _struct default=see below_: a struct of configuration options used to configure the API calls. These values are used for all subsequent API requests unless values are overridden on an individual basis or are modified using the `setSetting()` method. Default values are:

```
{
   "apiEndPoint": "", // required
   "apiUserName": "",
   "apiPassword": "",
   "apiBearer": "",
   "timeout": 10,
   "camelDashes": false,
   "lowerCase": false,
   "contentType": "",
   "charset": "utf-8",
   "headers": {},
   "postData": {},
   "cookies": {},
   "query": {}
}
```

The only required setting is `apiEndPoint`. This is used to defined the base URL for the API that you are calling.


| Property | Default | Notes |
| :-------- | :------ | :---- |
| apiEndPoint (required) | "" | This is the baseURL for the API. For example `https://postman-echo.com/` |
| apiUserName | "" | A username to use for basic authentication |
| apiPassword | "" | A password to use for basic authentication |
| apiBearer | "" | A token to use for beaerer authentication. This gets added as an `Authorization` header in the form `Bearer <apiBearer>` |
| timeout | 10 | A timeout value in seconds for the http requests |
| camelDashes | false | If ture, CamelCase requests get converted to dash seperated strings. For example `GetCamelCase()` will call a `Camel-Case` endpoint using the `GET` http verb |
| lowerCase | false | If true, enpoints are converted to lowercase |
| contentType | "" | A default value to use for the `Content-Type` header |
| charset | "utf-8" | A default charset for requests |
| headers | {} | A struct defining default headers. This can be used set default headers for all requests, or requests using speific HTTP verbs. See below for an example. |
| postData | {} | A struct containing key-value pairs describing data to be included in requests other then `GET` as form fields |
| cookies | {} | A struct containing key-value pairs describing cookies to be included in all requests |
| query | {} | A struct containing key-value pairs describing data to form a query string to be included in all requests |


### Example 'headers' configuration
```
headers: {
   // 'common' headers will be included in every request
   common: {
      "Authorization": "Token in here"
   },
   // 'post' headers will just be include in POST requests. A similar structure can be used for all other HTTP verbs
   post: {
      "Content-Type": "application/x-www-form-urlencoded"
   }
}
```

### Default settings at runtime
You can modify default settings using a hepller function `setSetting()`. For example:

```
api.setSetting("cookies", {
   "X-CSRF-TOKEN": "Cookie value"
});
```

Headers can be modified using a slightly different technique making use of the `getSetting()` helper function.
```
api.getSetting("headers").common["Authorization"] = "My token value";
```


## Making a request
Requests to the API are made by prepending the HTTP verb that you wish to use to the endpoint of the API that you wish to call:

```
result = api.GetEndpoint( [requestSettings] );
```

### Request settings
* `settings` _struct default=see below_: a struct of optional configuration options used to configure an individual API calls. Possible parameters are:

```
{
   "apiPath": "",
   "body": "",
   "postData": {},
   "query": {},
   "headers": {},
   "cookies": {},
   "timeout": settings.timeout,
   "bearer": settings.apiBearer,
   "contentType": settings.contentType,
   "charset": settings.charset,
   "username": settings.apiUsername,
   "password": settings.apiPassword
}
```

| Property | Default | Notes |
| :-------- | :------ | :---- |
| apiPath | "" | This gets added to the API base URL and the endpoint being called. For example a value of `/now` used on a call of `GetTime` will result in an endpoint of `time/now` |
| body | "" | Either a string or a struct of data to use in the body of the request. A struct will be converted to a JSON string |
| postData | {} | A struct containing key-value pairs describing data to be sent as form fields for this request. This will be merged with any default value |
| query | {} | A struct containing key-value pairs describing data to form a query string for this request. This will be merged with any default value |
| headers | {} | A struct containing key-value pairs describing data to use for request headers for this request. This will be merged with any default value for the HTTP verb being used |
| cookies | {} | A struct containing key-value pairs describing data to use for cookies for this request. This will be merged with any default value |
| timeout | settings.timeout | A timeout value in seconds for this http request. If set, this will override the default value |
| bearer | settings.apiBearer | A token to use for beaerer authentication. This gets added as an `Authorization` header in the form `Bearer <apiBearer>`. If set, this will override the default value |
| contentType | settings.contentType | A value to use for the `Content-Type` header for this http request. If set, this will override the default value |
| charset | settings.charset | A value to use for the charset for this http request. If set, this will override the default value |
| username | settings.apiUsername | A username to use for basic authentication for this request. If set, this will override the default value |
| password | settings.apiPassword | A password to use for basic authentication for this request. If set, this will override the default value |


## Examples

```
api = new genericAPIWrapper({
   apiEndPoint: "https://postman-echo.com/",
   apiUsername: "postman",
   apiPassword: "password",
   camelDashes: true,
   lowerCase: true
});

// https://postman-echo.com/basic-auth
result = api.GetBasicAuth();

// https://postman-echo.com/time/now
result = api.GetTime( { apiPath: "/now" } );

// https://postman-echo.com/time/add?timestamp=2016-10-10&years=100
result = api.GetTime( { 
   apiPath: "/add",
   query: {
      "timestamp": "2016-10-10",
      "years": 100
   }
} );

```


