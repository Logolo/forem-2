// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
//= require jquery.autocomplete
//= require forem
//
$(document).ready(function() {
  group_id = $('#new_member').data('group-id');

  add_member = function() {
    user = $("#new_member").val()
    $.post(Forem.base_path + '/admin/groups/' + group_id + '/members', { user: user })
    $("#new_member").val("")
    $('#members').append('<li>' + user + '</li>')
  }

  $('#new_member').keypress(function(e){
    if (e.which == 13) {
      add_member();
    }
  })
})
