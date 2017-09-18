function delete_key(unique_id){
	var r = confirm("Are you sure to delete?");
	if (r == true) {
		$.getJSON("/api_delete_key?key="+unique_id,function(html){
			if(html.success){
				location.reload();
			}else{
				alert('Sorry, failed to delete '+unique_id);
			}
		});
	}
}
function guid() {
  function s4() {
    return Math.floor((1 + Math.random()) * 0x10000)
      .toString(16)
      .substring(1);
  }
  return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
    s4() + '-' + s4() + s4() + s4();
}
function getUrlVars() {
    var vars = {};
    var parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi,    
    function(m,key,value) {
      vars[key] = value;
    });
    return vars;
}
	function dataAsJson(name){
		var x = $("#"+name).serializeArray();
		var outputObj = new Object();
    	$.each(x, function(i, field){
    		if(field.value!=""){
    			outputObj[field.name]   = field.value;
    		}
     	});
    	return outputObj;
    }
function generate_manual_code(name,code){
	var val=$("#"+name).val();
	var patt=/[^A-Za-z0-9_-]/g;
	var result=val.replace(patt,' ');
	result=result.replace(/-/g, ' ');
	result=result.replace(/\s+/g, ' ');
	result = result.replace(/^\s+|\s+$/g,'');
	result=result.replace(/\s/g, '-');
	result=result.toLowerCase();
	$("#"+code).val(result);
}
function load_navigator(){
	var drawMenu= '<li class="active treeview"><a href="index.html"><i class="fa fa-dashboard"></i> <span>Dashboard</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a></li>';
	drawMenu+= '<li class=" treeview"><a href="#"><i class=" fa fa-list"></i> <span>Lists</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a><ul class="treeview-menu"><li class="active"><a href="lists.html"><i class="fa fa-circle-o"></i> Lists</a></li><li class="active"><a href="list.html"><i class="fa fa-circle-o"></i> Add New List</a></li></ul></li>';
	drawMenu+= '<li class=" treeview"><a href="#"><i class=" fa fa-server"></i> <span>Hosts</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a><ul class="treeview-menu"><li class="active"><a href="hosts.html"><i class="fa fa-circle-o"></i> List Hosts</a></li><li class="active"><a href="host.html"><i class="fa fa-circle-o"></i> Add New Host</a></li></ul></li>';
	drawMenu+= '<li class=" treeview"><a href="#"><i class="fa fa-life-ring"></i> <span>Rules</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a><ul class="treeview-menu"><li class="active"><a href="rules.html"><i class="fa fa-circle-o"></i> List Rules</a></li><li class="active"><a href="rule.html"><i class="fa fa-circle-o"></i> Add New Rule</a></li></ul></li>';
	drawMenu+= '<li class=" treeview"><a href="#"><i class="fa fa-globe"></i> <span>Sites</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a><ul class="treeview-menu"><li class="active"><a href="sites.html"><i class="fa fa-circle-o"></i> List Sites</a></li><li class="active"><a href="site.html"><i class="fa fa-circle-o"></i> Add New Site</a></li></ul></li>';
	drawMenu+= '<li class=" treeview"><a href="#"><i class=" fa fa-arrow-circle-o-up"></i> <span>Upstreams</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a><ul class="treeview-menu"><li class="active"><a href="upstreams.html"><i class="fa fa-circle-o"></i> List Upstreams </a></li><li class="active"><a href="upstream.html"><i class="fa fa-circle-o"></i> Add New Upstream</a></li></ul></li>';
	drawMenu+= '<li class=" treeview"><a href="#"><i class="fa fa-globe"></i> <span>Urls</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a><ul class="treeview-menu"><li class="active"><a href="urls.html"><i class="fa fa-circle-o"></i> List Urls </a></li><li class="active"><a href="url_form.html"><i class="fa fa-circle-o"></i> Add New Url</a></li></ul></li>';
	drawMenu+= '<li class=" treeview"><a href="#"><i class="fa fa-folder-open"></i> <span>Templates</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a><ul class="treeview-menu"><li class="active"><a href="templates.html"><i class="fa fa-circle-o"></i> List Templates </a></li><li class="active"><a href="template.html"><i class="fa fa-circle-o"></i> Add New Template</a></li></ul></li>';
	drawMenu+= '<li class=" treeview"><a href="#"><i class="fa fa-file-text"></i> <span>Tokens</span><span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i></span></a><ul class="treeview-menu"><li class="active"><a href="tokens.html"><i class="fa fa-circle-o"></i> List Tokens </a></li><li class="active"><a href="token.html"><i class="fa fa-circle-o"></i> Add New Token</a></li></ul></li>';

	$("#main_menu_ui").html(drawMenu);
}
$(document).ready(function() {
	load_navigator();
});