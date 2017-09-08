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