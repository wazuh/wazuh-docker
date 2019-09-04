/**
 * Wazuh RESTful API
 * Copyright (C) 2015-2019 Wazuh, Inc. All rights reserved.
 * Wazuh.com
 *
 * This program is a free software; you can redistribute it
 * and/or modify it under the terms of the GNU General Public
 * License (version 2) as published by the FSF - Free Software
 * Foundation.
 */


var router = require('express').Router();

/**
 * @api {get} /agents Get all agents
 * @apiName GetAgents
 * @apiGroup Info
 *
 * @apiParam {Number} [offset] First element to return in the collection.
 * @apiParam {Number} [limit=500] Maximum number of elements to return.
 * @apiParam {String} [select] Select which fields to return (separated by comma).
 * @apiParam {String} [sort] Sorts the collection by a field or fields (separated by comma). Use +/- at the beginning to list in ascending or descending order.
 * @apiParam {String} [search] Looks for elements with the specified string.
 * @apiParam {String} [select] List of selected fields separated by commas.
 * @apiParam {String="active", "pending", "neverconnected", "disconnected"} [status] Filters by agent status. Use commas to enter multiple statuses.
 * @apiParam {String} [q] Query to filter results by. For example q="status=Active"
 * @apiParam {String} [older_than] Filters out disconnected agents for longer than specified. Time in seconds, '[n_days]d', '[n_hours]h', '[n_minutes]m' or '[n_seconds]s'. For never connected agents, uses the register date.
 * @apiParam {String} [os.platform] Filters by OS platform.
 * @apiParam {String} [os.version] Filters by OS version.
 * @apiParam {String} [os.name] Filters by OS name.
 * @apiParam {String} [manager] Filters by manager hostname to which agents are connected.
 * @apiParam {String} [version] Filters by agents version.
 * @apiParam {String} [group] Filters by group of agents.
 * @apiParam {String} [node_name] Filters by node name.
 * @apiParam {String} [name] Filters by agent name.
 * @apiParam {String} [ip] Filters by agent IP.
 *
 * @apiDescription Returns a list with the available agents.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents?pretty&offset=0&limit=5&sort=-ip,name"
 *
 */
router.get('/', cache(), function(req, res) {
    var query_checks = {'status':'alphanumeric_param', 'os.platform':'alphanumeric_param',
                         'os.version':'alphanumeric_param', 'manager':'alphanumeric_param',
                         'version':'alphanumeric_param', 'node_name': 'alphanumeric_param',
                         'older_than':'timeframe_type', 'group':'alphanumeric_param',
                         'name': 'alphanumeric_param', 'ip': 'ips',
                         'os.name':'alphanumeric_param' };
    templates.array_request("/agents", req, res, "agents", {}, query_checks);
})

/**
 * @api {get} /agents/summary Get agents summary
 * @apiName GetAgentsSummary
 * @apiGroup Info
 *
 *
 * @apiDescription Returns a summary of the available agents.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/summary?pretty"
 *
 */
router.get('/summary', cache(), function(req, res) {
    logger.debug(req.connection.remoteAddress + " GET /agents/summary");

    req.apicacheGroup = "agents";

    var data_request = {'function': '/agents/summary', 'arguments': {}};
    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {get} /agents/summary/os Get OS summary
 * @apiName GetOSSummary
 * @apiGroup Info
 *
 * @apiParam {Number} [offset] First element to return in the collection.
 * @apiParam {Number} [limit=500] Maximum number of elements to return.
 * @apiParam {String} [sort] Sorts the collection by a field or fields (separated by comma). Use +/- at the beginning to list in ascending or descending order.
 * @apiParam {String} [search] Looks for elements with the specified string.
 * @apiParam {String} [q] Query to filter result. For example q="status=Active"
 *
 * @apiDescription Returns a summary of the OS.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/summary/os?pretty"
 *
 */
router.get('/summary/os', cache(), function(req, res) {
    templates.single_field_array_request("/agents/summary/os", req, res, "agents");
})

/**
 * @api {get} /agents/no_group Get agents without group
 * @apiName GetAgentsWithoutGroup
 * @apiGroup Groups
 *
 * @apiParam {Number} [offset] First element to return in the collection.
 * @apiParam {Number} [limit=500] Maximum number of elements to return.
 * @apiParam {String} [select] Select which fields to return (separated by comma).
 * @apiParam {String} [sort] Sorts the collection by a field or fields (separated by comma). Use +/- at the beginning to list in ascending or descending order.
 * @apiParam {String} [search] Looks for elements with the specified string.
 * @apiParam {String} [q] Query to filter result. For example q="status=Active"
 *
 * @apiDescription Returns a list with the available agents without group.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/no_group?pretty"
 *
 */
router.get('/no_group', cache(), function (req, res) {
    query_checks = {'status': 'alphanumeric_param'}
    templates.array_request('/agents/no_group', req, res, "agents", {}, query_checks);
})

/**
 * @api {get} /agents/groups Get groups
 * @apiName GetAgentGroups
 * @apiGroup Groups
 *
 * @apiParam {Number} [offset] First element to return in the collection.
 * @apiParam {Number} [limit=500] Maximum number of elements to return.
 * @apiParam {String} [sort] Sorts the collection by a field or fields (separated by comma). Use +/- at the beginning to list in ascending or descending order.
 * @apiParam {String} [search] Looks for elements with the specified string.
 * @apiParam {String} [hash] Select algorithm to generate the sum.
 *
 * @apiDescription Returns the list of existing agent groups.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/groups?pretty"
 *
 */
router.get('/groups', cache(), function(req, res) {
    logger.debug(req.connection.remoteAddress + " GET /agents/groups");

    req.apicacheGroup = "agents";

    var data_request = {'function': '/agents/groups', 'arguments': {}};
    var filters = {'offset': 'numbers', 'limit': 'numbers', 'sort':'sort_param',
                   'search':'search_param', 'hash':'names'};

    if (!filter.check(req.query, filters, req, res))  // Filter with error
        return;

    if ('offset' in req.query)
        data_request['arguments']['offset'] = Number(req.query.offset);
    if ('limit' in req.query)
        data_request['arguments']['limit'] = Number(req.query.limit);
    if ('sort' in req.query)
        data_request['arguments']['sort'] = filter.sort_param_to_json(req.query.sort);
    if ('search' in req.query)
        data_request['arguments']['search'] = filter.search_param_to_json(req.query.search);
    if ('hash' in req.query)
        data_request['arguments']['hash_algorithm'] = req.query.hash

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {get} /agents/groups/:group_id Get agents in a group
 * @apiName GetAgentGroupID
 * @apiGroup Groups
 *
 * @apiParam {String} group_id Group ID.
 * @apiParam {Number} [offset] First element to return in the collection.
 * @apiParam {Number} [limit=500] Maximum number of elements to return.
 * @apiParam {String} [select] Select which fields to return (separated by comma).
 * @apiParam {String} [sort] Sorts the collection by a field or fields (separated by comma). Use +/- at the beginning to list in ascending or descending order.
 * @apiParam {String} [search] Looks for elements with the specified string.
 * @apiParam {String="active", "pending", "neverconnected", "disconnected"} [status] Filters by agent status.
 * @apiParam {String} [q] Query to filter results by.
 *
 * @apiDescription Returns the list of agents in a group.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/groups/dmz?pretty"
 *
 */
router.get('/groups/:group_id', cache(), function(req, res) {
    param_checks = {'group_id':'names'};
    query_checks = {'status': 'alphanumeric_param'}

    templates.array_request('/agents/groups/:group_id', req, res, "agents", param_checks, query_checks);
});


/**
 * @api {get} /agents/groups/:group_id/configuration Get group configuration
 * @apiName GetAgentGroupConfiguration
 * @apiGroup Groups
 *
 * @apiParam {String} group_id Group ID.
 * @apiParam {Number} [offset] First element to return in the collection.
 * @apiParam {Number} [limit=500] Maximum number of elements to return.
 *
 * @apiDescription Returns the group configuration (agent.conf).
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/groups/dmz/configuration?pretty"
 *
 */
router.get('/groups/:group_id/configuration', cache(), function(req, res) {
    logger.debug(req.connection.remoteAddress + " GET /agents/groups/:group_id/configuration");

    req.apicacheGroup = "agents";

    var data_request = {'function': '/agents/groups/:group_id/configuration', 'arguments': {}};
    var filters = {'offset': 'numbers', 'limit': 'numbers'};

    if (!filter.check(req.params, {'group_id':'names'}, req, res))  // Filter with error
        return;

    data_request['arguments']['group_id'] = req.params.group_id;


    if (!filter.check(req.query, filters, req, res))  // Filter with error
        return;

    if ('offset' in req.query)
        data_request['arguments']['offset'] = Number(req.query.offset);
    if ('limit' in req.query)
        data_request['arguments']['limit'] = Number(req.query.limit);

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {post} /agents/groups/:group_id/configuration Put configuration file (agent.conf) into a group
 * @apiName PostAgentGroupConfiguration
 * @apiGroup Groups
 *
 * @apiParam {String} group_id Group ID.
 *
 * @apiDescription Upload the group configuration (agent.conf).
 *
 * @apiExample {curl} Example usage*:
 *     curl -u foo:bar -X POST -H 'Content-type: application/xml' -d @agent.conf.xml "https://127.0.0.1:55000/agents/groups/dmz/configuration?pretty" -k
 *
 */
router.post('/groups/:group_id/configuration', function(req, res) {
    logger.debug(req.connection.remoteAddress + " POST /agents/groups/:group_id/configuration");

    var data_request = {'function': 'POST/agents/groups/:group_id/configuration', 'arguments': {}};
    var filters = {'group_id': 'names'};

    if (!filter.check(req.params, filters, req, res))  // Filter with error
        return;
    
    if (!filter.check_xml(req.body, req, res)) return;

    data_request['arguments']['group_id'] = req.params.group_id;
    try {
        data_request['arguments']['tmp_file'] = require('../helpers/files').tmp_file_creator(req.body);
    } catch(err) {
        res_h.bad_request(req, res, 702, err);
        return;
    }
    
    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {post} /agents/groups/:group_id/files/:file_name Upload file into a group
 * @apiName PostAgentGroupFile
 * @apiGroup Groups
 *
 * @apiParam {String} group_id Group ID.
 * @apiParam {String} file_name File name.
 *
 * @apiDescription Upload a file to a group.
 *
 * @apiExample {curl} Example usage*:
 *     curl -u foo:bar -X POST -H 'Content-type: application/xml' -d @agent.conf.xml "https://127.0.0.1:55000/agents/groups/dmz/files/agent.conf?pretty" -k
 *
 */
router.post('/groups/:group_id/files/:file_name', function(req, res) {
    logger.debug(req.connection.remoteAddress + " POST /agents/groups/:group_id/files/:file_name");

    var data_request = {'function': 'POST/agents/groups/:group_id/files/:file_name', 'arguments': {}};
    var filters = {'group_id': 'names', 'file_name': 'names'};

    if (!filter.check(req.params, filters, req, res))  // Filter with error
        return;

    if (!filter.check_xml(req.body, req, res)) return;

    data_request['arguments']['group_id'] = req.params.group_id;
    try {
        data_request['arguments']['tmp_file'] = require('../helpers/files').tmp_file_creator(req.body);
    } catch(err) {
        res_h.bad_request(req, res, 702, err);
        return;
    }
    data_request['arguments']['file_name'] = req.params.file_name;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {get} /agents/groups/:group_id/files/:filename Get a file in group
 * @apiName GetAgentGroupFile
 * @apiGroup Groups
 *
 * @apiParam {String} [group_id] Group ID.
 * @apiParam {String} [file_name] Filename
 * @apiParam {String="conf","rootkit_files", "rootkit_trojans", "rcl"} [type] Type of file.
 * @apiParam {String="json","xml"} [format] Optional. Output format (JSON, XML).
 * 
 * @apiDescription Returns the specified file belonging to the group parsed to JSON.
 *
 * @apiExample {curl} Example usage*:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/groups/webserver/files/cis_debian_linux_rcl.txt?pretty"
 *
 */
router.get('/groups/:group_id/files/:filename', cache(), function(req, res) {
    logger.debug(req.connection.remoteAddress + " GET /agents/groups/:group_id/files/:filename");

    req.apicacheGroup = "agents";

    var data_request = {'function': '/agents/groups/:group_id/files/:filename', 'arguments': {}};
    var filters = {'group_id': 'names', 'filename': 'names'};

    if (!filter.check(req.params, filters, req, res))  // Filter with error
        return;

    data_request['arguments']['group_id'] = req.params.group_id;
    data_request['arguments']['filename'] = req.params.filename;

    if (!filter.check(req.query, {'type': 'names', 'format': 'format'}, req, res))  // Filter with error
        return;

    if ('type' in req.query)
        data_request['arguments']['type_conf'] = req.query.type;

    if ('format' in req.query) 
        data_request['arguments']['return_format'] = req.query.format;
            
    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {get} /agents/groups/:group_id/files Get group files
 * @apiName GetAgentGroupFiles
 * @apiGroup Groups
 *
 * @apiParam {String} group_id Group ID.
 * @apiParam {Number} [offset] First element to return in the collection.
 * @apiParam {Number} [limit=500] Maximum number of elements to return.
 * @apiParam {String} [sort] Sorts the collection by a field or fields (separated by comma). Use +/- at the beginning to list in ascending or descending order.
 * @apiParam {String} [search] Looks for elements with the specified string.
 * @apiParam {String} [hash] Hash algorithm to use to calculate files checksums.
 *
 * @apiDescription Returns the files belonging to the group.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/groups/default/files?pretty"
 *
 */
router.get('/groups/:group_id/files', cache(), function(req, res) {
    logger.debug(req.connection.remoteAddress + " GET /agents/groups/:group_id/files");

    req.apicacheGroup = "agents";

    var data_request = {'function': '/agents/groups/:group_id/files', 'arguments': {}};
    var filters = {'offset': 'numbers', 'limit': 'numbers', 'sort':'sort_param', 'search':'search_param', 'hash':'names'};

    if (!filter.check(req.query, filters, req, res))  // Filter with error
        return;

    if ('offset' in req.query)
        data_request['arguments']['offset'] = Number(req.query.offset);
    if ('limit' in req.query)
        data_request['arguments']['limit'] = Number(req.query.limit);
    if ('sort' in req.query)
        data_request['arguments']['sort'] = filter.sort_param_to_json(req.query.sort);
    if ('search' in req.query)
        data_request['arguments']['search'] = filter.search_param_to_json(req.query.search);
    if ('hash' in req.query)
        data_request['arguments']['hash_algorithm'] = req.query.hash;

    if (!filter.check(req.params, {'group_id':'names'}, req, res))  // Filter with error
        return;

    data_request['arguments']['group_id'] = req.params.group_id;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {get} /agents/outdated Get outdated agents
 * @apiName GetOutdatedAgents
 * @apiGroup Upgrade
 *
 * @apiParam {Number} [offset] First element to return in the collection.
 * @apiParam {Number} [limit=500] Maximum number of elements to return.
 * @apiParam {String} [sort] Sorts the collection by a field or fields (separated by comma). Use +/- at the beginning to list in ascending or descending order.
 * @apiParam {String} [q] Query to filter result. For example q="status=Active"
 *
 * @apiDescription Returns the list of outdated agents.
 *
 * @apiExample {curl} Example usage*:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/outdated?pretty"
 *
 */
router.get('/outdated', cache(), function(req, res) {
    templates.array_request("/agents/outdated",req,res,"agents");
})


/**
 * @api {get} /agents/name/:agent_name Get an agent by its name
 * @apiName GetAgentsName
 * @apiGroup Info
 *
 * @apiParam {String} agent_name Agent name.
 * @apiParam {String} [select] List of selected fields separated by commas.
 *
 * @apiDescription Returns various information from an agent called :agent_name.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/name/NewHost?pretty"
 *
 */
router.get('/name/:agent_name', cache(), function(req, res) {
    logger.debug(req.connection.remoteAddress + " GET /agents/name/:agent_name");

    req.apicacheGroup = "agents";

    var data_request = {'function': '/agents/name/:agent_name', 'arguments': {}};
    var filters = {'select':'select_param'};

    if (!filter.check(req.params, {'agent_name':'names'}, req, res))  // Filter with error
        return;

    data_request['arguments']['agent_name'] = req.params.agent_name;

    if(!filter.check(req.query, filters, req, res)) // Filter with error
        return;

    if ('select' in req.query)
        data_request['arguments']['select'] =
        filter.select_param_to_json(req.query.select);

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });

})

/**
 * @api {get} /agents/:agent_id Get an agent
 * @apiName GetAgentsID
 * @apiGroup Info
 *
 * @apiParam {Number} agent_id Agent ID.
 * @apiParam {String} [select] List of selected fields separated by commas.
 *
 * @apiDescription Returns various information from an agent.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/000?pretty"
 *
 */
router.get('/:agent_id', cache(), function(req, res) {
    logger.debug(req.connection.remoteAddress + " GET /agents/:agent_id");

    req.apicacheGroup = "agents";

    var data_request = {'function': '/agents/:agent_id', 'arguments': {}};
    var filters = {'select':'select_param'};

    if (!filter.check(req.params, {'agent_id':'numbers'}, req, res))  // Filter with error
        return;

    data_request['arguments']['agent_id'] = req.params.agent_id;

    if(!filter.check(req.query, filters, req, res)) // Filter with error
        return;

    if ('select' in req.query)
        data_request['arguments']['select'] =
        filter.select_param_to_json(req.query.select);

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });

})

/**
 * @api {get} /agents/:agent_id/key Get agent key
 * @apiName GetAgentsKey
 * @apiGroup Key
 *
 * @apiParam {Number} agent_id Agent ID.
 *
 * @apiDescription Returns the key of an agent.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/004/key?pretty"
 *
 */
router.get('/:agent_id/key', function(req, res) {
    logger.debug(req.connection.remoteAddress + " GET /agents/:agent_id/key");

    var data_request = {'function': '/agents/:agent_id/key', 'arguments': {}};

    if (!filter.check(req.params, {'agent_id':'numbers'}, req, res))  // Filter with error
        return;

    data_request['arguments']['agent_id'] = req.params.agent_id;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {get} /agents/:agent_id/upgrade_result Get upgrade result from agent
 * @apiName GetUpgradeResult
 * @apiGroup Upgrade
 *
 * @apiParam {Number} agent_id Agent ID.
 * @apiParam {Number} [timeout=3] Seconds to wait for the agent to respond.
 *
 * @apiDescription Returns the upgrade result from an agent.
 *
 * @apiExample {curl} Example usage*:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/003/upgrade_result?pretty"
 *
 */
router.get('/:agent_id/upgrade_result', function(req, res) {
    logger.debug(req.connection.remoteAddress + " GET /agents/:agent_id/upgrade_result");

    var data_request = {'function': '/agents/:agent_id/upgrade_result', 'arguments': {}};

    if (!filter.check(req.query, {'timeout':'numbers'}, req, res))  // Filter with error
        return;

    if (!filter.check(req.params, {'agent_id':'numbers'}, req, res))  // Filter with error
        return;

    data_request['arguments']['agent_id'] = req.params.agent_id;
    if ('timeout' in req.query)
        data_request['arguments']['timeout'] = req.query.timeout;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})


/**
 * @api {get} /agents/:agent_id/config/:component/:configuration Get active configuration
 * @apiName GetConfig
 * @apiGroup Config
 *
 * @apiParam {Number} agent_id Agent ID.
 * @apiParam {String="agent","agentless","analysis","auth","com","csyslog","integrator","logcollector","mail","monitor","request","syscheck","wmodules"} component Selected component.
 * @apiParam {String="client","buffer","labels","internal","agentless","global","active_response","alerts","command","rules","decoders","internal","auth","active-response","internal","cluster","csyslog","integration","localfile","socket","remote","syscheck","rootcheck","wmodules"} configuration Configuration to read.
 *
 * @apiDescription Returns the active configuration in JSON format.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/001/config/logcollector/localfile?pretty"
 *
 */
 router.get('/:agent_id/config/:component/:configuration', function(req, res) {     
    logger.debug(req.connection.remoteAddress + " GET /agents/:agent_id/config/:component/:configuration");

    var data_request = {'function': '/agents/:agent_id/config/:component/:configuration', 'arguments': {}};

    if (!filter.check(req.params, {'agent_id':'numbers', 'component':'names', 'configuration':'names'}, req, res))  // Filter with error
        return;

    data_request['arguments']['agent_id'] = req.params.agent_id;
    data_request['arguments']['component'] = req.params.component;
    data_request['arguments']['configuration'] = req.params.configuration;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

 /**
 * @api {get} /agents/:agent_id/group/is_sync Get sync status of agent
 * @apiName GetSync
 * @apiGroup Group
 *
 * @apiParam {Number} agent_id Agent ID.
 *
 * @apiDescription Returns the sync status in JSON format
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/001/group/is_sync?pretty"
 *
 */
router.get('/:agent_id/group/is_sync', function(req, res) {     
    param_checks = {'agent_id': 'numbers'};     
    templates.array_request('/agents/:agent_id/group/is_sync', req, res, "agents", param_checks);
})


/**
 * @api {put} /agents/restart Restart all agents
 * @apiName PutAgentsRestart
 * @apiGroup Restart
 *
 * @apiDescription Restarts all agents.
 *
 * @apiExample {curl} Example usage*:
 *     curl -u foo:bar -k -X PUT "https://127.0.0.1:55000/agents/restart?pretty"
 *
 */
router.put('/restart', function(req, res) {
    logger.debug(req.connection.remoteAddress + " PUT /agents/restart");

    var data_request = {'function': 'PUT/agents/restart', 'arguments': {}};

    data_request['arguments']['restart_all'] = 'True';

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {post} /agents/restart Restart a list of agents
 * @apiName PostAgentListRestart
 * @apiGroup Restart
 *
 * @apiParam {String[]} ids Array of agent ID's.
 *
 * @apiDescription Restarts a list of agents.
 *
 * @apiExample {curl} Example usage*:
 *     curl -u foo:bar -k -X POST -H "Content-Type:application/json" -d '{"ids":["002","004"]}' "https://127.0.0.1:55000/agents/restart?pretty"
 *
 */
router.post('/restart', function(req, res) {
    logger.debug(req.connection.remoteAddress + " POST /agents/restart");

    var data_request = {'function': 'POST/agents/restart', 'arguments': {}};

    if (!filter.check(req.body, {'ids':'array_numbers'}, req, res))  // Filter with error
        return;

    data_request['arguments']['agent_id'] = req.body.ids;

    if ('ids' in req.body){
        data_request['arguments']['agent_id'] = req.body.ids;
        execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
    }else
        res_h.bad_request(req, res, 604, "Missing field: 'ids'");
})

/**
 * @api {put} /agents/:agent_id/restart Restart an agent
 * @apiName PutAgentsRestartId
 * @apiGroup Restart
 *
 * @apiParam {Number} agent_id Agent unique ID.
 *
 * @apiDescription Restarts the specified agent.
 *
 * @apiExample {curl} Example usage*:
 *     curl -u foo:bar -k -X PUT "https://127.0.0.1:55000/agents/007/restart?pretty"
 *
 */
router.put('/:agent_id/restart', function(req, res) {
    logger.debug(req.connection.remoteAddress + " PUT /agents/:agent_id/restart");

    var data_request = {'function': 'PUT/agents/:agent_id/restart', 'arguments': {}};

    if (!filter.check(req.params, {'agent_id':'numbers'}, req, res))  // Filter with error
        return;

    data_request['arguments']['agent_id'] = req.params.agent_id;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {put} /agents/:agent_id/upgrade Upgrade agent using online repository
 * @apiName PutAgentsUpgradeId
 * @apiGroup Upgrade
 *
 * @apiParam {Number} agent_id Agent unique ID.
 * @apiParam {String} [wpk_repo] WPK repository.
 * @apiParam {String} [version] Wazuh version.
 * @apiParam {Boolean} [use_http] Use protocol HTTP. If it is false use HTTPS. By default the value is set to false.
 * @apiParam {number="0","1"} [force] Force upgrade.
 *
 * @apiDescription Upgrade the agent using a WPK file from online repository.
 *
 * @apiExample {curl} Example usage*:
 *     curl -u foo:bar -k -X PUT "https://127.0.0.1:55000/agents/002/upgrade?pretty"
 *
 */
router.put('/:agent_id/upgrade', function(req, res) {
    logger.debug(req.connection.remoteAddress + " PUT /agents/:agent_id/upgrade");

    var data_request = {'function': 'PUT/agents/:agent_id/upgrade', 'arguments': {}};
    var filters = { 'wpk_repo': 'paths', 'version': 'alphanumeric_param', 'force': 'numbers', 'use_http': 'boolean'};

    if (!filter.check(req.params, {'agent_id':'numbers'}, req, res))
        return;

    if (!filter.check(req.query, filters, req, res))
        return;

    data_request['arguments']['agent_id'] = req.params.agent_id;
    if ('wpk_repo' in req.query)
        data_request['arguments']['wpk_repo'] = req.query.wpk_repo;
    if ('version' in req.query)
        data_request['arguments']['version'] = req.query.version;
    if ('force' in req.query)
        data_request['arguments']['force'] = req.query.force;
    if ('use_http' in req.query)
        data_request['arguments']['use_http'] = (req.query.use_http == true || req.query.use_http == 'true');

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {put} /agents/:agent_id/upgrade_custom Upgrade agent using custom file
 * @apiName PutAgentsUpgradeCustomId
 * @apiGroup Upgrade
 *
 * @apiParam {Number} agent_id Agent unique ID.
 * @apiParam {String} file_path Path to the WPK file. The file must be on a folder on the Wazuh's installation directory (by default, ``/var/ossec``).
 * @apiParam {String} installer Installation script.
 *
 * @apiDescription Upgrade the agent using a custom file.
 *
 * @apiExample {curl} Example usage*:
 *     curl -u foo:bar -k -X PUT "https://127.0.0.1:55000/agents/002/upgrade_custom?pretty"
 *
 */
router.put('/:agent_id/upgrade_custom', function(req, res) {
    logger.debug(req.connection.remoteAddress + " PUT /agents/:agent_id/upgrade_custom");

    var data_request = {'function': 'PUT/agents/:agent_id/upgrade_custom', 'arguments': {}};
    var filters = {'file_path':'paths', 'installer':'alphanumeric_param'};

    if (!filter.check(req.params, {'agent_id':'numbers'}, req, res))
        return;

    if (!filter.check(req.query, filters, req, res))
        return;

    data_request['arguments']['agent_id'] = req.params.agent_id;
    if ('file_path' in req.query)
        data_request['arguments']['file_path'] = req.query.file_path;
    if ('installer' in req.query)
        data_request['arguments']['installer'] = req.query.installer;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {put} /agents/:agent_name Add agent (quick method)
 * @apiName PutAddAgentName
 * @apiGroup Add
 *
 * @apiParam {String} agent_name Agent name.
 *
 * @apiDescription Adds a new agent with name :agent_name. This agent will use ANY as IP.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X PUT "https://127.0.0.1:55000/agents/myNewAgent?pretty"
 *
 */
router.put('/:agent_name', function(req, res) {
    logger.debug(req.connection.remoteAddress + " PUT /agents/:agent_name");

    var data_request = {'function': 'PUT/agents/:agent_name', 'arguments': {}};

    if (!filter.check(req.params, {'agent_name':'names'}, req, res))  // Filter with error
        return;

    data_request['arguments']['name'] = req.params.agent_name;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {put} /agents/groups/:group_id Create a group
 * @apiName PutGroup
 * @apiGroup Groups
 *
 * @apiParam {String} group_id Group ID.
 *
 * @apiDescription Creates a new group.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X PUT "https://127.0.0.1:55000/agents/groups/pciserver?pretty"
 *
 */
router.put('/groups/:group_id', function(req, res) {
    logger.debug(req.connection.remoteAddress + " PUT /agents/groups/:group_id");

    var data_request = {'function': 'PUT/agents/groups/:group_id', 'arguments': {}};
    var filters = {'group_id':'names'};

    if (!filter.check(req.params, filters, req, res))  // Filter with error
        return;

    data_request['arguments']['group_id'] = req.params.group_id;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {put} /agents/:agent_id/group/:group_id Add agent group
 * @apiName PutGroupAgent
 * @apiGroup Groups
 *
 * @apiParam {Number} agent_id Agent unique ID.
 * @apiParam {String} group_id Group ID.
 * @apiParam {Boolean} force_single_group Wheter to append new group to current agent's group or replace it.
 *
 * @apiDescription Adds an agent to the specified group.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X PUT "https://127.0.0.1:55000/agents/004/group/dmz?pretty"
 *
 */
router.put('/:agent_id/group/:group_id', function(req, res) {
    logger.debug(req.connection.remoteAddress + " PUT /agents/:agent_id/group/:group_id");

    var data_request = {'function': 'PUT/agents/:agent_id/group/:group_id', 'arguments': {}};
    var filters = {'agent_id':'numbers', 'group_id':'names', 'force_single_group': 'empty_boolean'};

    if (!filter.check(req.params, filters, req, res))  // Filter with error
        return;

    data_request['arguments']['agent_id'] = req.params.agent_id;
    data_request['arguments']['group_id'] = req.params.group_id;
    data_request['arguments']['replace'] = 'force_single_group' in req.query && req.query.replace != 'false' ? true : false;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})


/**
 * @api {post} /agents/group/:group_id Add a list of agents to a group
 * @apiName PostGroupAgents
 * @apiGroup Groups
 *
 * @apiParam {String[]} ids List of agents ID.
 * @apiParam {String} group_id Group ID.
 *
 * @apiDescription Adds a list of agents to the specified group.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -X POST -H "Content-Type:application/json" -d '{"ids":["001","002"]}' "https://localhost:55000/agents/group/dmz?pretty" -k
 *
 */
router.post('/group/:group_id', function(req, res) {
    logger.debug(req.connection.remoteAddress + " POST /agents/group/:group_id");

    var data_request = {'function': 'POST/agents/group/:group_id', 'arguments': {}};
    var filters = {'group_id': 'names', 'ids': 'array_numbers'}

    if (!filter.check(req.params, filters, req, res))  // Filter with error
        return;

    data_request['arguments']['group_id'] = req.params.group_id;
    data_request['arguments']['agent_id_list'] = req.body.ids;

    if ('ids' in req.body){
        execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
    }else
        res_h.bad_request(req, res, 604, "Missing field: 'ids'");
})


/**
 * @api {delete} /agents/groups Delete a list of groups
 * @apiName DeleteAgentsGroups
 * @apiGroup Delete
 *
 * @apiParam {String} ids Name of groups separated by commas.
 *
 * @apiDescription Removes a list of groups.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X DELETE "https://127.0.0.1:55000/agents/groups?ids=webserver,database&pretty"
 *
 */
router.delete('/groups', function(req, res) {
    logger.debug(req.connection.remoteAddress + " DELETE /agents/groups");

    var data_request = {'function': 'DELETE/agents/groups', 'arguments': {}};

    if (!filter.check(req.query, {'ids': 'array_names'}, req, res))  // Filter with error
        return;

    if ('ids' in req.query){
        if (typeof(req.query.ids) == 'string') {
            data_request['arguments']['group_id'] = req.query.ids.split(',');
        } else {
            data_request['arguments']['group_id'] = req.query.ids;
        }
        execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
    }else
        res_h.bad_request(req, res, 604, "Missing field: 'ids'");
})


/**
 * @api {delete} /agents/:agent_id Delete an agent
 * @apiName DeleteAgentId
 * @apiGroup Delete
 *
 * @apiParam {Number} agent_id Agent ID.
 * @apiParam {Boolean} purge Delete an agent from the key store. This parameter is only valid if purge is set to no in the manager's ossec.conf.
 *
 * @apiDescription Removes an agent.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X DELETE "https://127.0.0.1:55000/agents/008?pretty&purge"
 *
 */
router.delete('/:agent_id', function(req, res) {
    logger.debug(req.connection.remoteAddress + " DELETE /agents/:agent_id");

    var data_request = {'function': 'DELETE/agents/:agent_id', 'arguments': {}};

    if (!filter.check(req.params, {'agent_id':'numbers'}, req, res))  // Filter with error
        return;

    data_request['arguments']['agent_id'] = req.params.agent_id;
    data_request['arguments']['purge'] = 'purge' in req.query && req.query.purge != 'false' ? true : false;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {delete} /agents/:agent_id/group Remove all agent groups.
 * @apiName DeleteGroupAgent
 * @apiGroup Groups
 *
 * @apiParam {Number} agent_id Agent ID.
 *
 * @apiDescription Removes the group of the agent. The agent will automatically revert to the 'default' group.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X DELETE "https://127.0.0.1:55000/agents/004/group?pretty"
 *
 */
router.delete('/:agent_id/group', function(req, res) {
    logger.debug(req.connection.remoteAddress + " DELETE /agents/:agent_id/group");

    var data_request = {'function': 'DELETE/agents/:agent_id/group', 'arguments': {}};

    if (!filter.check(req.params, {'agent_id':'numbers'}, req, res))  // Filter with error
        return;

    data_request['arguments']['agent_id'] = req.params.agent_id;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {delete} /agents/:agent_id/group/:group_id Remove a single group of an agent
 * @apiName DeleteGroupAgent
 * @apiGroup Groups
 *
 * @apiParam {Number} agent_id Agent ID.
 * @apiParam {String} group_id Group ID.
 *
 * @apiDescription Remove the group of the agent but will leave the rest of its group if it belongs to a multigroup.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X DELETE "https://127.0.0.1:55000/agents/004/group/dmz?pretty"
 *
 */
router.delete('/:agent_id/group/:group_id', function(req, res) {
    logger.debug(req.connection.remoteAddress + " DELETE /agents/:agent_id/group/:group_id");

    var data_request = {'function': 'DELETE/agents/:agent_id/group/:group_id', 'arguments': {}};

    if (!filter.check(req.params, {'agent_id':'numbers', 'group_id': 'names'}, req, res))  // Filter with error
        return;

    data_request['arguments']['agent_id'] = req.params.agent_id;
    data_request['arguments']['group_id'] = req.params.group_id;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {delete} /agents/group/:group_id Remove a single group of multiple agents
 * @apiName DeleteGroupAgents
 * @apiGroup Groups
 *
 * @apiParam {String} ids Agent IDs separated by commas.
 * @apiParam {String} group_id Group ID.
 *
 * @apiDescription Remove a list of agents of a group
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X DELETE "https://localhost:55000/agents/group/dmz?ids=001,002&pretty"
 *
 */
router.delete('/group/:group_id', function(req, res) {
    logger.debug(req.connection.remoteAddress + " DELETE /agents/group/:group_id");

    var data_request = {'function': 'DELETE/agents/group/:group_id', 'arguments': {}};
    var filters_param = {'group_id': 'names'}
    var filters_query = {'ids': 'array_numbers'}

    if (!filter.check(req.params, filters_param, req, res))  // Filter with error (path params)
        return;
    if (!filter.check(req.query, filters_query, req, res))  // Filter with error (query params)
        return;

    data_request['arguments']['group_id'] = req.params.group_id;

    if ('ids' in req.query) {
        if (typeof(req.query.ids) == 'string') {
            data_request['arguments']['agent_id_list'] = req.query.ids.split(',');
        } else {
            data_request['arguments']['agent_id_list'] = req.query.ids;
        }
    }

    if ('ids' in req.query){
        execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
    }else
        res_h.bad_request(req, res, 604, "Missing field: 'ids'");
})

/**
 * @api {delete} /agents/groups/:group_id Remove group
 * @apiName DeleteGroupAgents
 * @apiGroup Groups
 *
 * @apiParam {String} group_id Group ID.
 *
 * @apiDescription Removes the group. Agents that were assigned to the removed group will automatically revert to the 'default' group.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X DELETE "https://127.0.0.1:55000/agents/groups/dmz?pretty"
 *
 */
router.delete('/groups/:group_id', function(req, res) {
    logger.debug(req.connection.remoteAddress + " DELETE /agents/groups/:group_id");

    var data_request = {'function': 'DELETE/agents/groups/:group_id', 'arguments': {}};

    if (!filter.check(req.params, {'group_id':'names'}, req, res))  // Filter with error
        return;

    data_request['arguments']['group_id'] = req.params.group_id;
    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})

/**
 * @api {delete} /agents Delete agents
 * @apiName DeleteAgents
 * @apiGroup Delete
 *
 * @apiParam {String} ids Agent IDs separated by commas.
 * @apiParam {Boolean} purge Delete an agent from the key store. This parameter is only valid if purge is set to no in the manager's ossec.conf.
 * @apiParam {String="active", "pending", "neverconnected", "disconnected"} [status] Filters by agent status. Use commas to enter multiple statuses.
 * @apiParam {String} older_than Filters out disconnected agents for longer than specified. Time in seconds, '[n_days]d', '[n_hours]h', '[n_minutes]m' or '[n_seconds]s'. For never connected agents, uses the register date. Default value: 7d.
 *
 * @apiDescription Removes agents, using a list of them or a criterion based on the status or time of the last connection. The Wazuh API must be restarted after removing an agent.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X DELETE "https://127.0.0.1:55000/agents?older_than=10s&purge&ids=003,005&pretty"
 *
 */
router.delete('/', function(req, res) {
    logger.debug(req.connection.remoteAddress + " DELETE /agents");

    var data_request = {'function': 'DELETE/agents/', 'arguments': {}};
    var filters_query = {'older_than': 'timeframe_type', 'status': 'alphanumeric_param', 'purge': 'empty_boolean',
                         'ids': 'array_numbers'};

    if (!filter.check(req.query, filters_query, req, res))  // Filter with error
        return;

    if (!('ids' in req.query) && !('status' in req.query)){
        res_h.bad_request(req, res, 604, "Missing field: You have to specified 'ids' or status.");
        return;
    }

    if ('purge' in req.query && req.query.purge != 'false')
        data_request['arguments']['purge'] = true;
    else
        data_request['arguments']['purge'] = false;

    if ('ids' in req.query) {
        if (typeof(req.query.ids) == 'string') {
            data_request['arguments']['list_agent_ids'] = req.query.ids.split(',');
        } else {
            data_request['arguments']['list_agent_ids'] = req.query.ids;
        }
    }

    if ('older_than' in req.query)
        data_request['arguments']['older_than'] = req.query.older_than;

    if ('status' in req.query)
        data_request['arguments']['status'] = req.query.status;

    execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
})


/**
 * @api {post} /agents Add agent
 * @apiName PostAddAgentId
 * @apiGroup Add
 *
 * @apiParam {String} name Agent name.
 * @apiParam {String="IP","IP/NET", "ANY"} [ip] If this is not included, the API will get the IP automatically. If you are behind a proxy, you must set the option config.BehindProxyServer to yes at config.js.
 * @apiParam {Number} [force] Remove the old agent with the same IP if disconnected since <force> seconds.
 *
 * @apiDescription Add a new agent.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X POST -d '{"name":"NewHost","ip":"10.0.0.9"}' -H 'Content-Type:application/json' "https://127.0.0.1:55000/agents?pretty"
 *
 */
router.post('/', function(req, res) {
    logger.debug(req.connection.remoteAddress + " POST /agents");

    // If not IP set, we will use source IP.
    var ip = req.body.ip;
    if ( !ip ){
        // If we hare behind a proxy server, use headers.
        if (config.BehindProxyServer.toLowerCase() == "yes")
            if (!req.headers.hasOwnProperty('x-forwarded-for')){
                res_h.bad_request(req, res, 800);
                return;
            }
            else
                ip = req.headers['x-forwarded-for'];
        else
            ip = req.connection.remoteAddress;

        // Extract IPv4 from IPv6 hybrid notation
        if (ip.indexOf("::ffff:") > -1) {
            var ipFiltered = ip.split(":");
            ip = ipFiltered[ipFiltered.length-1];
            logger.debug("Hybrid IPv6 IP filtered: " + ip);
        }
        logger.debug("Add agent with automatic IP: " + ip);
    }
    req.body.ip = ip;

    var data_request = {'function': 'POST/agents', 'arguments': {}};
    var filters = {'name':'names', 'ip':'ips', 'force':'numbers'};

    if (!filter.check(req.body, filters, req, res))  // Filter with error
        return;

    data_request['arguments']['ip'] = req.body.ip;

    if ('name' in req.body){
        data_request['arguments']['name'] = req.body.name;
        if ('force' in req.body){
            data_request['arguments']['force'] = req.body.force;
        }
        execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
    }else
        res_h.bad_request(req, res, 604, "Missing field: 'name'");
})


/**
 * @api {post} /agents/insert Insert agent
 * @apiName PostInsertAgent
 * @apiGroup Add
 *
 * @apiParam {String} name Agent name.
 * @apiParam {String="IP","IP/NET", "ANY"} [ip] If this is not included, the API will get the IP automatically. If you are behind a proxy, you must set the option config.BehindProxyServer to yes at config.js.
 * @apiParam {String} id Agent ID.
 * @apiParam {String} key Agent key. Minimum length: 64 characters. Allowed values: ^[a-zA-Z0-9]+$
 * @apiParam {Number} [force] Remove the old agent the with same IP if disconnected since <force> seconds.
 *
 * @apiDescription Insert an agent with an existing id and key.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X POST -d '{"name":"NewHost_2","ip":"10.0.10.10","id":"123","key":"1abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghi64"}' -H 'Content-Type:application/json' "https://127.0.0.1:55000/agents/insert?pretty"
 *
 */
router.post('/insert', function(req, res) {
    logger.debug(req.connection.remoteAddress + " POST /agents/insert");

    // If not IP set, we will use source IP.
    var ip = req.body.ip;
    if ( !ip ){
        // If we hare behind a proxy server, use headers.
        if (config.BehindProxyServer.toLowerCase() == "yes")
            if (!req.headers.hasOwnProperty('x-forwarded-for')){
                res_h.bad_request(req, res, 800);
                return;
            }
            else
                ip = req.headers['x-forwarded-for'];
        else
            ip = req.connection.remoteAddress;

        // Extract IPv4 from IPv6 hybrid notation
        if (ip.indexOf("::ffff:") > -1) {
            var ipFiltered = ip.split(":");
            ip = ipFiltered[ipFiltered.length-1];
            logger.debug("Hybrid IPv6 IP filtered: " + ip);
        }
        logger.debug("Add agent with automatic IP: " + ip);
    }
    req.body.ip = ip;

    var data_request = {'function': 'POST/agents/insert', 'arguments': {}};
    var filters = {'name':'names', 'ip':'ips', 'id':'numbers', 'key': 'ossec_key', 'force':'numbers'};

    if (!filter.check(req.body, filters, req, res))  // Filter with error
        return;

    data_request['arguments']['id'] = req.body.id;
    data_request['arguments']['name'] = req.body.name;
    data_request['arguments']['ip'] = req.body.ip;
    data_request['arguments']['key'] = req.body.key;
    if ('force' in req.body){
        data_request['arguments']['force'] = req.body.force;
    }

    if ('id' in req.body && 'name' in req.body && 'ip' in req.body && 'key' in req.body){
        execute.exec(python_bin, [wazuh_control], data_request, function (data) { res_h.send(req, res, data); });
    }else
        res_h.bad_request(req, res, 604, "Missing fields. Mandatory fields: id, name, ip, key");
})



/**
 * @api {get} /agents/stats/distinct Get distinct fields in agents
 * @apiName GetdistinctAgents
 * @apiGroup Stats
 *
 * @apiParam {Number} [offset] First element to return in the collection.
 * @apiParam {Number} [limit=500] Maximum number of elements to return.
 * @apiParam {String} [sort] Sorts the collection by a field or fields (separated by comma). Use +/- at the beginning to list in ascending or descending order.
 * @apiParam {String} [search] Looks for elements with the specified string.
 * @apiParam {String} [fields] List of fields affecting the operation.
 * @apiParam {String} [select] List of selected fields separated by commas.
 * @apiParam {String} [q] Query to filter result. For example q="status=Active"
 *
 * @apiDescription Returns all the different combinations that agents have for the selected fields. It also indicates the total number of agents that have each combination.
 *
 * @apiExample {curl} Example usage:
 *     curl -u foo:bar -k -X GET "https://127.0.0.1:55000/agents/stats/distinct?pretty&fields=os.platform"
 *
 */
router.get('/stats/distinct', cache(), function (req, res) {
    query_checks = {'fields':'select_param'};
    templates.array_request('/agents/stats/distinct', req, res, "agents", {}, query_checks);
})

module.exports = router;