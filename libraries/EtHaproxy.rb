class Chef::Recipe::EtHaproxy

  def self.nodes_for_recipes(env,backends)

    recipes = backends.select{|be,be_conf|
      be_conf['servers_recipe']
    }.map{|be,be_conf|
      be_conf['servers_recipe']
    }

    recipe_search_string = recipes.map{|r| "recipes:" + r }.join(' OR ')
    clusters = Hash.new
    recipes.each do |rec|
      clusters[rec] = []
    end
    r = Chef::Search::Query.new.search(:node, "chef_environment:#{env} AND (#{recipe_search_string})").first
    r.each{|n|
      cluster_recipe = (recipes&n.recipes).first
      clusters[cluster_recipe] << n
    }

    return clusters

  end

end
