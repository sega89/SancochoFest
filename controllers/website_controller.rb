class WebsiteController < ApplicationController

	## almundo.com
	get '/', :host_name => /^(dev.|www.|)almundo.com$/ do
		NewRelic::Agent.set_transaction_name("Home::Splash")

		cookie = request.cookies[$cookie_selected_country_name]

		if cookie != nil
			data_country = $business_domain.detect {|bd| bd['country_code'] == cookie.upcase}
			redirect data_country['url']
		end

		erb :splash, :layout => :"layouts/clean"
	end

	## franquicias.almundo.com
	get '/', :host_name => /^(dev.|www.|)franquicias.almundo.com$/ do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Landings::Franchise")
		erb :franchise, :layout => :"layouts/clean"
	end

	## empresas.almundo.com
	get '/', :host_name => /^(dev.|www.|)empresas.almundo.com$/ do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Landings::Corporate")
		erb :enterprise, :layout => :"layouts/clean"
	end

	## almundo.com.{pais}
	get '/' do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Home::Home")

		offers_product = @current_product != "flights" ? "hotels" : "mixed"
		get_offers_for_product offers_product

		@comments =	Comment.where().limit(12)
		@banners = Banner.all(:country_code => @current_country_code);
		@product_class = I18n.t("products.#{@current_product}.class")

		erb :home
	end

	get %r{^/(vuelos|passagens-aereas)(\/|)$} do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Flights::Home")

		get_offers_for_product "flights"

		@comments =	Comment.where({:product_code => "TKT"}).limit(12)
		@banners = Banner.all(:country_code => @current_country_code);
		@product_class = I18n.t("products.flights.class")

		erb :flights
	end

	get %r{^/(hoteles|hoteis)(\/|)$} do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Hotels::Home")

		get_offers_for_product "hotels"

		@comments =	Comment.where({:product_code => "HTL"}).limit(12)
		@banners = Banner.all(:country_code => @current_country_code);
		@product_class = I18n.t("products.hotels.class")

		erb :hotels
	end

	get %r{^/paquetes-turisticos(\/|)$} do
			NewRelic::Agent.set_transaction_name("#{@current_country_code}::Packages::Home")

			@zones =	PackageZone.all
			@comments =	Comment.where().limit(12)
			@banners = Banner.all(:country_code => @current_country_code);
			@product_class = I18n.t("products.packages.class")

			erb :packages
	end

	get %r{^/autos(\/|)$} do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Cars::Home")

		get_offers_for_product "mixed"
		@comments =	Comment.where({:product_code => "CAR"}).limit(12)
		@banners = Banner.all(:country_code => @current_country_code);
		@product_class = I18n.t("products.cars.class")

		erb :cars
	end

	get %r{^/cruceros(\/|)$} do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Cruises::Home")

		get_offers_for_product "mixed"
		@zones =	CruiseZone.all
		@comments =	Comment.where({:product_code => "CRU"}).limit(12)
		@banners = Banner.all(:country_code => @current_country_code);
		@product_class = I18n.t("products.cruices.class")

		erb :cruises
	end

	get %r{^/actividades(\/|)$} do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Excursions::Home")

		get_offers_for_product "mixed"
		@comments =	Comment.where({:product_code => "ACT"}).limit(12)
		@banners = Banner.all(:country_code => @current_country_code);
		@product_class = I18n.t("products.excursions.class")

		erb :excursions
	end


	get %r{/(viajes|viagens)/[\w]+} do |canonical|
		code = params[:code]

		if code.instance_of?(String)
			code = code.upcase
		end

		@destination = Destination.first(:$or => [{:iata_code => code}, {:zone_code => code}], :site => @current_country_code.downcase)

		if @destination == nil
			halt 404, "site not found"
		end

		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Landings::Destinations::(#{@destination['iata_code']})#{@destination['city_name']}")

		@comments =	Comment.where().limit(12)
		hotel_offers = HotelOffer.where(:country_code => @current_country_code, :zone_code => @destination.zone_code, :destiny_name => {:$exists => true}).limit(1)
		flight_offers = FlightOffer.where(:country_code => @current_country_code, :destiny_code => @destination.iata_code, :destiny_name => {:$exists => true}).limit(1)
		@offers = hotel_offers.to_a + flight_offers.to_a

		erb :destinations
	end

	get %r{^/por-que-comprar(\/|)$} do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Landings::Reasons_To_Buy")
		erb :reasontobuy
	end

	get %r{^/quienes-somos(\/|)$} do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Landings::About_Us")
		erb :aboutus
	end

	get %r{^/institucional(\/|)$} do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Landings::Press")
		erb :press, :layout => :"layouts/clean"
	end

	## club.almundo.com
	get %r{^/club-almundo(\/|)$} do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Club_Almundo::Home")
		erb :clubalmundo
	end

	## empleos.almundo.com
	get %r{^/empleos(\/|)$} do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Landings::Jobs")
		erb :jobs, :layout => :"layouts/clean"
	end

	## mejorprecio.almundo.com
	get %r{^/mejor-precio-y-servicio(\/|)$} do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Landings::Best_Price")
		erb :bestprice
	end

	## cybermonday.almundo.com
	get %r{^/cyber-monday(\/|)$} do
		NewRelic::Agent.set_transaction_name("#{@current_country_code}::Landings::Cyber_Monday")
		erb :cybermonday
	end

	##################################
	## =>	PRIVATE METHODS
	##################################

	private

	def get_offers_for_product product

		case product
		when "mixed"
			hotel_offers = HotelOffer.where(:country_code => @current_country_code).sort(:quantity.desc).limit(4)
			flight_offers = FlightOffer.where(:country_code => @current_country_code).sort(:quantity.desc).limit(5)
			@offers = hotel_offers.to_a + flight_offers.to_a
		when "flights"
			@offers = FlightOffer.where(:country_code => @current_country_code).sort(:quantity.desc).limit(9).to_a
		when "hotels"
			hotel_offers = HotelOffer.where(:country_code => @current_country_code, :destiny_name => {:$exists => true}).sort(:quantity.desc).limit(9)
			@offers = hotel_offers.to_a

			while @offers.size < 9 && @offers.size > 0
				@offers += hotel_offers.to_a
			end
		else
			@offers = []
		end

	end

end
