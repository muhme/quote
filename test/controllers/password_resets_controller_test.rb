require 'test_helper'

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @first_user = users(:first_user)
  end
  
  # GET /password_resets/new
  test "get password reset page" do
    get new_password_reset_url
    assert_response :success
    assert_match /Passwort zurücksetzen/, @response.body
  end
  
  # GET /password_resets/1/edit
  test "fail to reset some users password" do
    get edit_password_reset_url id: @first_user
    assert_redirected_to root_url
    follow_redirect!
    assert_match /Das Zurücksetzen des Passworts für den Benutzereintrag .* ist nicht erlaubt./, @response.body
  end

  # POST /password_resets
  test "fail for not existing email address" do
    post password_resets_url, :params => { :email => 'bla' }
    assert_response :unprocessable_entity # 422
    assert_match /Kein Benutzer mit der E-Mail .*bla.* gefunden!/, @response.body
  end

  # POST /password_resets
  test "reset user login with existing email address" do
    post password_resets_url, :params => { :email => @first_user.email }
    assert_redirected_to root_url
    follow_redirect!
    assert_match /Eine E-Mail mit dem Link zum Zurücksetzen des Passworts wurde an .*#{@first_user.email}.* gesendet./, @response.body
    # try reset now
    last_email = ActionMailer::Base.deliveries.last
    #    <a href=3D"http://zitat-service.de/password_resets/V6mb1Fjyd4e7B_d4DAw=
    #    8/edit?login=3Dfirst_user">http://zitat-service.de/password_resets/V6mb1F=
    # /password_resets/V6mb1Fjyd4e7B_d4DAw8
    pt = last_email.body.encoded.sub(/.*(\/password_resets\/[^\/]+).*/m, '\1').sub(/=[\s]/, '')
    pt = pt.tr("\n", "") # delete new line from mail
    url = pt + "/edit?login=" + @first_user.login
    get url
    assert_response :success
    assert_match /Hier kannst Du ein neues Passwort für den Benutzernamen .* setzen./, @response.body
    # do it, e.g. http://192.168.99.100:8102/password_resets/qh2cSjNijWcZ4iwaeuAD
    put pt, params: { :login => @first_user.login, :password => 'new45678', :password_confirmation => 'new45678'}
    assert_redirected_to root_url
    follow_redirect!
    assert_match /Das Passwort für .* wurde erfolgreich aktualisiert./, @response.body
  end

  # POST /password_resets
  test "reset user login with existing email address after login" do
    login :first_user
    assert_redirected_to root_url
    follow_redirect!
    assert_match /Hallo #{@first_user.login}, schön dass Du da bist/, @response.body
    # logged-in user is not a real live exmaple, but may happen by using URLs 
    post password_resets_url, :params => { :email => @first_user.email }
    assert_redirected_to root_url
    follow_redirect!
    assert_match /Eine E-Mail mit dem Link zum Zurücksetzen des Passworts wurde an .*#{@first_user.email}.* gesendet./, @response.body
  end

end
