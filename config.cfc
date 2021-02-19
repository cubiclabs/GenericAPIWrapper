component{

	this.cfMapping = "api";
	this.register = "";

	this.config = {
		localAPI: {
			apiEndPoint: "https://" & cgi.http_host & "/api/v1/"
		}
	};

	function configure(){

		local.moduleConfig = Bolt().getConfig().modules;
		if(structKeyExists(local.moduleConfig, "genericAPIs")){

			local.apis = local.moduleConfig.genericAPIs;

			for(local.apiRef in structKeyArray(local.apis)){

				if(structKeyExists(this.config, local.apiRef)){
					local.initWith = this.config[local.apiRef];
					structAppend(local.initWith, local.apis[local.apiRef]);
				}else{
					local.initWith = local.apis[local.apiRef];
				}

				Bolt().register("#this.path#.genericAPIWrapper", this.subsystem)
					.as(local.apiRef & "@api")
					.withInitArg(name:"settings", value:local.initWith);

			}

		}

	}


	function development(){
		this.config.localAPI.apiEndPoint = "https://" & cgi.http_host & "/api/v1/";
	}
}