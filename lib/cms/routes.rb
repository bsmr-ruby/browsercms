module Cms::Routes
  
  def content_blocks(content_block_name, options={}, &block)
    content_block = content_block_name.to_s.classify.constantize
    resources(*[content_block_name, default_routes_for_content_block(content_block).deep_merge(options)], &block)
    if content_block.versioned?
      # I'm not sure why, but these named routes 
      # don't end up getting nested in the CMS namepace.
      # So for now I'm just hard-coding the stuff related to the CMS namespace
      send("version_cms_#{content_block_name}".to_sym, 
        "/cms/#{content_block_name}/:id/version/:version",
        :controller => "cms/#{content_block_name}",
        :action => "version",
        :conditions => {:method => :get})
      send("revert_to_cms_#{content_block_name}".to_sym, 
        "/cms/#{content_block_name}/:id/revert_to/:version",
        :controller => "cms/#{content_block_name}",
        :action => "revert_to",
        :conditions => {:method => :put})
    end
  end
  
  def default_routes_for_content_block(content_block)
    member_routes = {}
    member_routes[:publish] = :put if content_block.publishable?
    member_routes[:versions] = :get if content_block.versioned?
    member_routes[:usages] = :get if content_block.connectable?    
    {:member => member_routes}
  end
  
  def routes_for_browser_cms

    namespace(:cms) do |cms|
      
      cms.home '/', :controller => 'home'
      
      cms.logout '/logout', :controller => 'sessions', :action => 'destroy'
      cms.login '/login', :controller => 'sessions', :action => 'new', :conditions => { :method => :get }
      cms.connect '/login', :controller => 'sessions', :action => 'create', :conditions => { :method => :post }      
      cms.dashboard '/dashboard', :controller => 'dashboard'
      cms.sitemap '/sitemap', :controller => 'section_nodes'
      
      # TODO: Make an actual content library controller 
      # that redirects to the last content type you were working on
      cms.content_library '/content_library', :controller => 'html_blocks' 
      
      cms.content_blocks :html_blocks
      cms.content_blocks :portlets, :member => {:usages => :get}
      cms.content_blocks :file_blocks
      cms.content_blocks :image_blocks
      cms.content_blocks :category_types
      cms.content_blocks :categories
      cms.content_blocks :tags
      
      cms.administration '/administration', :controller => 'users'
      #cms.connect '/blocks/:block_type/:action/:id', :controller => 'blocks'
    end

    # connect '/:controller/:action/:id.:format'
    # connect '/:controller/:action.:format'
    # connect '/:controller/:action/:id'
    # connect '/:controller.:format'

    image_missing '/images/*path', :controller => 'cms/missing_asset'
    stylesheet_missing '/stylesheets/*path', :controller => 'cms/missing_asset'
    javascript_missing '/javascripts/*path', :controller => 'cms/missing_asset'

    connect '*path', :controller => 'cms/content', :action => 'show'    
  end
end
