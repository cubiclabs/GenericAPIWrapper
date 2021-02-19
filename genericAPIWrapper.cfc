component {
	
	/*

	
	headers can be defined in a similar way to axios
	headers.common = {} // headers for all requests
	headers.[httpMethod] = {} // header for specific http methods - GET, POST, etc

	*/

	variables._settings = {
		"apiUserName": "",
		"apiPassword": "",
		"apiEndPoint": "",
		"apiBearer": "",
		"timeout": 10,
		"camelDashes": false,
		"lowerCase": false,
		"contentType": "",
		"charset": "utf-8",
		"headers": {}, // default headers defined similar to axios
		"postData": {}, // default postData to send in requests other than GET
		"cookies": {}, // cookies to send with every request
		"httpMethods": listToArray("get,post,delete,put,patch,head,options,trace,connect")
	};

		
	/**
	* @hint constructor
	*/
	public any function init(struct settings){
		structAppend(variables._settings, arguments.settings);
		return this;
	}

	/**
	* @hint get a setting value
	*/
	public any function getSetting(string key){
		return variables._settings[arguments.key];
	}

	/**
	* @hint get our settings data
	*/
	public any function getSettings(){
		return variables._settings;
	}

	/**
	* @hint sets a setting value
	*/
	public void function setSetting(string key, any value){
		variables._settings[arguments.key] = arguments.value;
	}

	/**
	* @hint perform our API HTTP request
	*/
	public any function doRequest(
		string apiPath, 
		string httpMethod="GET", 
		any body="", 
		struct postData={},
		struct headers={},
		struct cookies={},
		numeric timeout=getSetting("timeout"),
		string bearer=getSetting("apiBearer"),
		string contentType=getSetting("contentType")){

		if(!len(getSetting("apiEndPoint"))){
			throw("No api endpoint is defined");
		}

		local.t = getTickCount();

		// ===================
		// define a HTTP request
		local.httpService = new http(
			method=arguments.httpMethod, 
			charset=getSetting("charset"), 
			url=getSetting("apiEndPoint") & arguments.apiPath,
			username=getSetting("apiUserName"),
			password=getSetting("apiPassword"),
			timeout=arguments.timeout);

		// ===================
		// look for a body
		if(isStruct(arguments.body) || len(arguments.body)){
			if(isStruct(arguments.body)){
				arguments.body = serializeJSON(arguments.body);
			}
			local.httpService.addParam(type:"body", value:arguments.body);
		}

		// ===================
		// form data
		local.requestPostData = {};
		structAppend(local.requestPostData, getSetting("postData"));
		structAppend(local.requestPostData, arguments.postData);
		for(local.fieldKey in structKeyArray(local.requestPostData)){
			local.httpService.addParam(type:"formField", name:local.fieldKey, value:local.requestPostData[local.fieldKey]);
		}

		// ===================
		// cookies
		local.requestCookies = {};
		structAppend(local.requestCookies, getSetting("cookies"));
		structAppend(local.requestCookies, arguments.cookies);
		for(local.cookieKey in structKeyArray(local.requestCookies)){
			local.httpService.addParam(type:"cookie", name:local.cookieKey, value:local.requestCookies[local.cookieKey]);
		}

		// ===================
		// headers
		// merge our headers to include any default settings, overriding values as we get more specific
		local.requestHeaders = {};
		if(structKeyExists(getSetting("headers"), "common")){
			structAppend(local.requestHeaders, getSetting("headers").common);
		}
		if(structKeyExists(getSetting("headers"), arguments.httpMethod)){
			structAppend(local.requestHeaders, getSetting("headers")[arguments.httpMethod]);
		}
		structAppend(local.requestHeaders, arguments.headers);

		
		if(!structKeyExists(local.requestHeaders, "Content-Type")){
			if(len(arguments.contentType)){
				local.requestHeaders["Content-Type"] = arguments.contentType;
			}else{
				if(len(arguments.body)){
					if(isJSON(arguments.body)){
						local.requestHeaders["Content-Type"] = "application/json";
					}else if(isXML(arguments.body)){
						local.requestHeaders["Content-Type"] = "application/xml";
					}
				}
			}
		}
		if(!structKeyExists(local.requestHeaders, "Authorization") && len(arguments.bearer)){
			local.requestHeaders["Authorization"] = "Bearer " & trim(arguments.bearer);
		}

		// add header values to our http request
		for(local.header in structKeyArray(local.requestHeaders)){
			local.httpService.addParam(type:"header", name:local.header, value:local.requestHeaders[local.header]);
		}

		// ===================
		// make our request
		local.result = local.httpService.send().getPrefix();

		// ===================
		// check for a JSON result
		if(isJSON(local.result.fileContent)){
			local.result.fileContent = deserializeJSON(local.result.fileContent);
		}

		// ===================
		// return our result
		local.result["request"] = {
			"params": local.httpService.getParams(),
			"attributes": local.httpService.getAttributes()
		};
		//local.result.request["apiEndPoint"] = getSetting("apiEndPoint");
		local.result["timer"] = getTickCount() - local.t;
		//local.result["service"] = local.httpService;
		
		return local.result;
	}


	/**
	* @hint used to proxy an API call
	*/
	public any function onMissingMethod(string missingMethodName, struct missingMethodArguments){
		
		local.apiArgs = {}

		for(local.httpMethod in getSetting("httpMethods")){
			if(left(arguments.missingMethodName, len(local.httpMethod)) == local.httpMethod){

				local.apiArgs.httpMethod = local.httpMethod;

				if(arrayLen(arguments.missingMethodArguments) != 1 || !isStruct(arguments.missingMethodArguments[1])){
					throw(type:"genericAPI", message:"expecting a single settings argument");
				}

				// merge our api request arguments/settings
				structAppend(local.apiArgs, arguments.missingMethodArguments[1]);

				// remove the http method from our method name
				local.apiMethod = replaceNoCase(arguments.missingMethodName, local.httpMethod, "");

				// check for camel case dash replacement
				if(getSetting("camelDashes")){
					local.apiMethod = reReplace(local.apiMethod, "([A-Z])", "-\1", "ALL");
					if(left(local.apiMethod, 1) == "-"){
						local.apiMethod = replace(local.apiMethod, "-", "");
					}
				}

				// check for force to lower case
				if(getSetting("lowerCase")){
					local.apiMethod = lcase(local.apiMethod);
				}

				// form our api apth
				if(structKeyExists(local.apiArgs, "apiPath")){
					local.apiArgs.apiPath = local.apiMethod & "/" & local.apiArgs.apiPath;
				}else{
					local.apiArgs.apiPath = local.apiMethod;
				}

				// do our api request
				return doRequest(argumentCollection:local.apiArgs);
			}
		}

		// not found...
		throw(type:"genericAPI", message: "Method '#encodeForHTML(arguments.missingMethodName)#' not found");
	}
	
	
}