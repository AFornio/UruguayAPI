class Api::V1::SupermarketsController < ApplicationController
  require 'httparty'
  require 'nokogiri'
  require 'json'

  SUPERMARKETS = %w[tienda_inglesa disco devoto tata].freeze
  BASKET_PRODUCTS = %w[arroz azucar panes leche aceite yerba].freeze

  CONFIGURATION = {
    tienda_inglesa: {
      source: "input[name='GXState']",
      product_collection_key: "vTOTALPRODUCTCOLLECTION",
      key_mapping: {
        "Name" => "name",
        "Price" => "price",
        "DefaultPicture.Small" => "image"
      },
    },
    disco: {
      source: ".render-route-store-search-subcategory script[type='application/ld+json']",
      product_collection_key: "itemListElement",
      key_mapping: {
        "item.name" => "name",
        "item.brand.name" => "brand",
        "item.offers.lowPrice" => "price",
        "item.image" => "image",
      },
    },
    devoto: {
      source: ".render-route-store-search-subcategory script[type='application/ld+json']",
      product_collection_key: "itemListElement",
      key_mapping: {
        "item.name" => "name",
        "item.brand.name" => "brand",
        "item.offers.lowPrice" => "price",
        "item.image" => "image",
      },
    },
    tata: {
      source: nil,
      product_collection_key: "data.search.products.edges",
      key_mapping: {
        "node.name" => "name",
        "node.offers.lowPrice" => "price",
        "node.brand.name" => "brand",
        "node.image.0.url" => "image"
      },
    }
  }.freeze

  FOOD_BASKET = {
		arroz: {
      tienda_inglesa: ["https://www.tiendainglesa.com.uy/Arroz.categoria?0,0,*:*,78,84,85="],
      disco: ["https://www.disco.com.uy/almacen/canasta-familiar/arroz", "https://www.disco.com.uy/almacen/canasta-familiar/arroz?page=2"],
      devoto: ["https://www.devoto.com.uy/almacen/canasta-familiar/arroz"],
      tata: ["https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%220%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22almacen%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22arroz-harina-y-legumbres%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22arroz%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D"],
		},
		azucar: {
			tienda_inglesa: ["https://www.tiendainglesa.com.uy/supermercado/categoria/almacen/azucar-edulcorante/azucar/78/87/1160"],
			disco: ["https://www.disco.com.uy/almacen/desayuno-merienda-y-postres/azucar"],
			devoto: ["https://www.devoto.com.uy/almacen/desayuno-merienda-y-postres/azucar"],
			tata: ["https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%220%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22almacen%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22desayuno%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22azucar-y-edulcorantes%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D"]
		},
		panes: {
			tienda_inglesa: [
				"https://www.tiendainglesa.com.uy/supermercado/categoria/frescos/panaderia/panes/busqueda?0,0,*%3A*,1894,217,225,%26forcechannel%3D1,,false,,,,0,0",
				"https://www.tiendainglesa.com.uy/supermercado/categoria/frescos/panaderia/panes/busqueda?0,0,*%3A*,1894,217,225,%26forcechannel%3D1,,false,,,,1",
				"https://www.tiendainglesa.com.uy/supermercado/categoria/frescos/panaderia/panes/busqueda?0,0,*%3A*,1894,217,225,%26forcechannel%3D1,,false,,,,2",
			],
			disco: [
				"https://www.disco.com.uy/frescos/panaderia/pan",
				"https://www.disco.com.uy/frescos/panaderia/pan?page=2",
			],
			devoto: [
				"https://www.devoto.com.uy/frescos/panaderia/pan",
				"https://www.devoto.com.uy/frescos/panaderia/pan?page=2",
			],
			tata: [
				"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%220%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22frescos%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22panaderia%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",
				"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%2218%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22frescos%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22panaderia%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",
				"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%2236%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22frescos%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22panaderia%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",
			],
		},
		leche: {
			tienda_inglesa: [
				"https://www.tiendainglesa.com.uy/supermercado/categoria/frescos/lacteos/leches/1894/209/211",
				"https://www.tiendainglesa.com.uy/supermercado/categoria/frescos/lacteos/leches/busqueda?0,0,*%3A*,1894,209,211,%26forcechannel%3D1,,false,,,,1"
			],
			disco: ["https://www.disco.com.uy/frescos/lacteos/leches"],
			devoto: ["https://www.devoto.com.uy/frescos/lacteos/leches"],
			tata: [
				"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%2218%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22frescos%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22lacteos%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22leches%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",
				"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%220%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22frescos%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22lacteos%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22leches%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",
				"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%2236%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22frescos%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22lacteos%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22leches%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",
			],
		},
		aceite: {
			tienda_inglesa: [
				"https://www.tiendainglesa.com.uy/supermercado/categoria/almacen/aceites-vinagres/78/79",
				"https://www.tiendainglesa.com.uy/supermercado/categoria/almacen/aceites-vinagres/busqueda?0,0,*%3A*,78,79,0,,,false,,,,1",
				"https://www.tiendainglesa.com.uy/supermercado/categoria/almacen/aceites-vinagres/busqueda?0,0,*%3A*,78,79,0,,,false,,,,2",
			],
			disco: [
				"https://www.disco.com.uy/almacen/canasta-familiar/aceites",
				"https://www.disco.com.uy/almacen/canasta-familiar/aceites?page=2",
				"https://www.disco.com.uy/almacen/canasta-familiar/aceites?page=3",
			],
			devoto: [
				"https://www.devoto.com.uy/almacen/canasta-familiar/aceites",
				"https://www.devoto.com.uy/almacen/canasta-familiar/aceites?page=2",
				"https://www.devoto.com.uy/almacen/canasta-familiar/aceites?page=3"
			],
			tata: [
			"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%2218%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22almacen%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22aceites-y-aderezos%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22aceites%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",
			"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%220%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22almacen%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22aceites-y-aderezos%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22aceites%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",
			"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%2236%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22almacen%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22aceites-y-aderezos%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22aceites%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",			
		],
		},
		yerba: {
			tienda_inglesa: [
				"https://www.tiendainglesa.com.uy/supermercado/categoria/almacen/yerba/78/172",
				"https://www.tiendainglesa.com.uy/supermercado/categoria/almacen/yerba/busqueda?0,0,*%3A*,78,172,0,,,false,,,,1"
			],
			disco: [
				"https://www.disco.com.uy/almacen/desayuno-merienda-y-postres/yerba",
				"https://www.disco.com.uy/almacen/desayuno-merienda-y-postres/yerba?page=2"
			],
			devoto: [
				"https://www.devoto.com.uy/almacen/desayuno-merienda-y-postres/yerba",
				"https://www.devoto.com.uy/almacen/desayuno-merienda-y-postres/yerba?page=2",
			],
			tata: [
				"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%2218%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22almacen%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22desayuno%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22yerbas%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",
				"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%220%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22almacen%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22desayuno%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22yerbas%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",
				"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%2236%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22almacen%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22desayuno%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22yerbas%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",
				"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%2254%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22almacen%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22desayuno%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22yerbas%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",
				"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%2272%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22almacen%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22desayuno%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22yerbas%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",
				"https://www.tata.com.uy/api/graphql?operationName=ProductsQuery&variables=%7B%22first%22%3A18%2C%22after%22%3A%2290%22%2C%22sort%22%3A%22score_desc%22%2C%22term%22%3A%22%22%2C%22selectedFacets%22%3A%5B%7B%22key%22%3A%22category-1%22%2C%22value%22%3A%22almacen%22%7D%2C%7B%22key%22%3A%22category-2%22%2C%22value%22%3A%22desayuno%22%7D%2C%7B%22key%22%3A%22category-3%22%2C%22value%22%3A%22yerbas%22%7D%2C%7B%22key%22%3A%22channel%22%2C%22value%22%3A%22%7B%5C%22salesChannel%5C%22%3A%5C%224%5C%22%2C%5C%22regionId%5C%22%3A%5C%22U1cjdGF0YXV5bW9udGV2aWRlbw%3D%3D%5C%22%7D%22%7D%2C%7B%22key%22%3A%22locale%22%2C%22value%22%3A%22es-UY%22%7D%5D%7D",			
			]
		}
  }.freeze


  def food_basket_store_product
    return render json: { error: "Store not found" }, status: :not_found unless SUPERMARKETS.include?(params[:store])
    return render json: { error: "Product not found" }, status: :not_found unless BASKET_PRODUCTS.include?(params[:product])

    store = params[:store].to_sym
    product = params[:product]
    urls = FOOD_BASKET.dig(product.to_sym, store)
    return render json: { error: "Product URLs not found" }, status: :not_found if urls.nil? || urls.empty?

    products_data = fetch_products_sequentially(store, urls)
    render json: { products: { store => products_data } }
  end
 
  def food_basket_store
    return render json: { error: "Store not found" }, status: :not_found unless SUPERMARKETS.include?(params[:store])

    store = params[:store].to_sym
    urls = FOOD_BASKET.values.map { |product_stores| product_stores[store] }.flatten.compact

    products_data = fetch_products_sequentially(store, urls)
    render json: { products: { store => products_data } }
  end

 
  def food_basket
    products_by_store = {}

    FOOD_BASKET.each do |product_name, stores_data|
      stores_data.each do |store_name, urls|
        fetched_products = fetch_products_for_product_and_store(store_name, urls)
        products_by_store[store_name] = (products_by_store[store_name] || []) + fetched_products
      end
    end

    render json: { products: products_by_store }
  end

  private

  def fetch_products_for_product_and_store(store, urls)
    all_products_for_store = []
    urls.each do |url|
      begin
        url = url.strip
        next if url.empty?

        response = HTTParty.get(url)
        
        product_collection_key = CONFIGURATION[store.to_sym][:product_collection_key]
        key_mapping = CONFIGURATION[store.to_sym][:key_mapping]

        product_collection = extract_json_data(response, store)

       
        product_collection_key.split('.').each do |nk|
          if product_collection.is_a?(Hash) && product_collection.key?(nk)
            product_collection = product_collection[nk]
          elsif product_collection.is_a?(Array) && nk.match?(/^\d+$/)
            index = nk.to_i
            product_collection = product_collection[index] if product_collection.length > index
          else
            product_collection = nil
            break
          end
        end

        next if product_collection.nil? || !product_collection.is_a?(Array)

       
        products = product_collection.map do |product_raw_data|
          product_info = {}
          key_mapping.each do |original_key_path, desired_key|
            value = product_raw_data
            original_key_path.split('.').each do |segment|
              if value.is_a?(Hash) && value.key?(segment)
                value = value[segment]
              elsif value.is_a?(Array) && segment.match?(/^\d+$/)
                index = segment.to_i
                value = value[index] if value.length > index
              else
                value = nil
                break
              end
            end
            product_info[desired_key.to_sym] = value
          end
          product_info
        end
        all_products_for_store.concat(products)
      rescue HTTParty::Error => e
        Rails.logger.error("HTTParty error fetching #{url} for #{store}: #{e.message}")
      rescue JSON::ParserError => e
        Rails.logger.error("JSON parsing error for #{url} for #{store}: #{e.message}")
      rescue StandardError => e
        Rails.logger.error("Unexpected error fetching #{url} for #{store}: #{e.message}")
      end
    end
    all_products_for_store
  end

  def fetch_products_sequentially(store, urls)
    all_products_for_store = []
    urls.each do |url|
      begin
        url = url.strip
        next if url.empty?

        response = HTTParty.get(url)
        
        product_collection_key = CONFIGURATION[store.to_sym][:product_collection_key]
        key_mapping = CONFIGURATION[store.to_sym][:key_mapping]

        product_collection = extract_json_data(response, store)

       
        product_collection_key.split('.').each do |nk|
          if product_collection.is_a?(Hash) && product_collection.key?(nk)
            product_collection = product_collection[nk]
          elsif product_collection.is_a?(Array) && nk.match?(/^\d+$/)
            index = nk.to_i
            product_collection = product_collection[index] if product_collection.length > index
          else
            product_collection = nil
            break
          end
        end

        next if product_collection.nil? || !product_collection.is_a?(Array)

       
        products = product_collection.map do |product_raw_data|
          product_info = {}
          key_mapping.each do |original_key_path, desired_key|
            value = product_raw_data
            original_key_path.split('.').each do |segment|
              if value.is_a?(Hash) && value.key?(segment)
                value = value[segment]
              elsif value.is_a?(Array) && segment.match?(/^\d+$/)
                index = segment.to_i
                value = value[index] if value.length > index
              else
                value = nil
                break
              end
            end
            product_info[desired_key.to_sym] = value
          end
          product_info
        end
        all_products_for_store.concat(products)
      rescue HTTParty::Error => e
        Rails.logger.error("HTTParty error fetching #{url} for #{store}: #{e.message}")
      rescue JSON::ParserError => e
        Rails.logger.error("JSON parsing error for #{url} for #{store}: #{e.message}")
      rescue StandardError => e
        Rails.logger.error("Unexpected error fetching #{url} for #{store}: #{e.message}")
      end
    end
    all_products_for_store
  end

  def extract_json_data(response, store)
    if CONFIGURATION[store.to_sym][:source].nil?
      JSON.parse(response.body)
    else
      doc = Nokogiri::HTML(response.body)
      source = CONFIGURATION[store.to_sym][:source]
      data_source = doc.css(source)
      return {} if data_source.empty?

      data_source_value = source.include?('input') ? data_source.first['value'] : data_source.first.text
      json_data = data_source_value ? JSON.parse(data_source_value) : {}
    end
  rescue JSON::ParserError => e
    Rails.logger.error("Error parsing JSON from response for store #{store}: #{e.message}")
    {}
  end
end