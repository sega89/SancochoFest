class ApplicationController < Sinatra::Base

	## Configuration
	configure do
		enable :sessions, :method_override, :logging
		set :logging, Logger::DEBUG
		set :public_folder, File.expand_path('../../public', __FILE__)
		set :views, File.expand_path('../../views', __FILE__)
		set :erb, :layout => :'layouts/default'

		configuration = {
			:config_folder => File.expand_path('../../config/business_domain', __FILE__), 
			:throw_exception => true,
			:exclude_paths => ['/task']
		}
		BusinessDomain.instance.register configuration
	end

	configure :test do
	end

	configure :development do
		register Sinatra::Reloader
		set :show_exceptions, false
		MongoMapper.setup({'development' => {'uri' => 'mongodb://test:test@localhost:27017/test'}}, 'development')
	end

	configure :production do
		NewRelic::Agent.manual_start
		MongoMapper.setup({'production' => {'uri' => 'mongodb://home:3mp6Q7@localhost:27017/home'}}, 'production')
	end

	## Helpers
	helpers Sinatra::ContentFor
	helpers Sinatra::AlMundo::Views::Partials
	helpers Sinatra::AlMundo::Home::StaticPaths

	## Filters
	before %r{^\/(?!.*(homepage-css|homepage-js)).*$} do

		show_or_hide_popup

		check_if_user_is_logged

		set_business_domain

		set_locale

		set_almundo_link

	end

	## Handling Errors
	not_found do
		NewRelic::Agent.set_transaction_name("(#{request.path})")
		NewRelic::Agent.add_custom_parameters( {"IP" => request.ip, "User-Agent" => request.user_agent} )

		logger.error "Error 404 - Not Found :: #{request.url}"
		erb :not_found, :layout => :"layouts/error"
	end

	error do
		I18n.locale = 'es-AR'
		logger.error "Application Error :: #{env['sinatra.error']}"
		erb :errors, :layout => :"layouts/error"
	end

	## Private Methods
	private

	def show_or_hide_popup
		@show_popup = true

		if request.cookies[$cookie_showpopup_name] == nil
			response.set_cookie($cookie_showpopup_name, :value => false, :expires => Time.now + $cookie_showpopup)
		else
			@show_popup = false
		end
	end

	def set_business_domain
		current_domain = request.scheme + "://" + request.host
		@current_business_domain = BusinessDomain.instance.check current_domain, request.script_name

		@current_locale = @current_business_domain['locale']
		@current_country_code = @current_business_domain['country_code']
		@current_product = @current_business_domain['site']['default_product']
		@current_main_city = @current_business_domain['main_city_code']
		@current_has_offices = @current_business_domain['site']['services']['offices']
		@current_has_phones = @current_business_domain['site']['services']['phones']
		@current_has_club = @current_business_domain['site']['services']['club']
		@current_has_warranty = @current_business_domain['site']['services']['warranty']
		@current_has_banks_offers = @current_business_domain['site']['services']['bank_offers']
		@current_has_comments = @current_business_domain['site']['services']['comments']
		@current_has_video = @current_business_domain['site']['services']['video']
		@current_has_promo_active = @current_business_domain['site']['services']['promo_active']
		@current_cdn = @current_business_domain['site']['cdn']
		@current_iata_cdn = @current_business_domain['site']['cdn_iata']
		@current_site_code = @current_business_domain['site']['code']

	end

	def set_locale
		I18n.locale = @current_locale
		logger.info "[I18n::Locale] '#{@current_locale}'"
	end

	def check_if_user_is_logged

		@is_logged = false
		@client_id, @client_sid, @client_name, @client_email, @client_photo, @client_points, @client_secret_id = nil

		if request.params.has_key?('tc')
			response.delete_cookie($cookie_expires_mialmundo_name)
			return
		end

		if @client_id != nil && @client_sid != nil
			return
		end

		if (cookie = request.cookies[$cookie_expires_mialmundo_name]) != nil
			data = JSON.parse(Base64.decode64(cookie))
			set_global_vars_for_user data
			return
		else
			if request.params.has_key?('token')
				token = request.params['token']
				set_global_vars_for_user JSON.parse(Base64.decode64(token))
				response.set_cookie($cookie_expires_mialmundo_name, :value => token, :expires => Time.now + $cookie_expires_mialmundo)
				return
			end
		end

	end

	def set_global_vars_for_user data
		@client_id = data['client_id']
		@client_sid = data['sid']
		@client_name = data['name']
		@client_email = data['email']
		@client_photo = data['photo']
		@client_points = data['points']

		@is_logged = true
		return
	end

	def set_almundo_link
		if (random = request.cookies[$cookie_secure_random_name]) == nil
			random = SecureRandom.hex(16)
			response.set_cookie($cookie_secure_random_name, :value => random, :expires => Time.now + $cookie_secure_random)
		end
		@almundo_link = "#{$service_endpoint_almundo}/?sid=#{@current_site_code}-#{random}"
	end

end
