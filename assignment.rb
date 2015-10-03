require 'sinatra'
require 'csv'
require 'pp'
require 'json'

class Listing
  attr_accessor :id, :street, :price, :bedrooms, :bathrooms, :sq_ft, :lat, :lng

  @@all = []
  def initialize params
    @id = params["id"].to_i
    @street = params["street"]
    @price = params["price"].to_i
    @bedrooms = params["bedrooms"].to_i
    @bathrooms = params["bathrooms"].to_i
    @sq_ft = params["sq_ft"].to_i
    @lat = params["lat"].to_f
    @lng = params["lng"].to_f
    @@all << self
  end

  def filter(opts = {})
    if opts[:min_price] and opts[:min_price] > @price
      return false
    elsif opts[:max_price] and opts[:max_price] < @price
      return false
    elsif opts[:min_bed] and opts[:min_bed] > @bedrooms
      return false
    elsif opts[:max_bed] and opts[:max_bed] < @bedrooms
      return false
    elsif opts[:min_bath] and opts[:min_bath] > @bathrooms
      return false
    elsif opts[:max_bath] and opts[:max_bath] < @bathrooms
      return false
    else
      return true
    end
  end

  def self.filter(opts ={}) 
    listings = @@all.select{ |listing| listing.filter(opts) }
    results = { type: "FeatureCollection", features: []}
    listings.each do |listing| 
      results[:features] << {
        type: "feature",
        geometry: { type: "Point", coordinates: [listing.lat, listing.lng]},
        properties: {
          id: listing.id,
          price: listing.price,
          street: listing.street,
          bedrooms: listing.bedrooms,
          bathrooms: listing.bathrooms,
          sq_ft: listing.sq_ft
        }
      }
    end
    results
  end
end

CSV.foreach("listings.csv", headers: true) do |obj|
  Listing.new(obj)
end

get '/listings' do
  opts = { 
            min_price: params[:min_price],
            max_price: params[:max_price],
            min_bed: params[:min_bed],
            max_bed: params[:max_bed],
            min_bath: params[:min_bath],
            max_bath: params[:max_bath],
         }
  opts.each {|key,val| opts[key] = val.to_i if val }
  listings = Listing.filter(opts)
  listings.to_json
end