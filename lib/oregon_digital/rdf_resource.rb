module OregonDigital
  class RdfResource < RDF::Graph
    extend RdfConfigurable
    extend RdfProperties

    def initialize(*args, &block)
      resource_uri = args.shift unless args.first.is_a?(Hash)
      set_subject!(resource_uri) if resource_uri
      self << RDF::Statement(self.rdf_subject, RDF::RDFS.label, type) if self.class.type.kind_of? RDF::URI
      super(*args, &block)
    end

    def rdf_subject
      @rdf_subject ||= RDF::Node.new
    end

    def node?
      return true if rdf_subject.kind_of? RDF::Node
      false
    end

    def base_uri
      self.class.base_uri
    end

    def type
      @type ||= self.class.type
    end

    def type=(type)
      raise "Type must be an RDF::URI" unless type.respond_to? :to_uri
      @type = type.to_uri
      self.set_value(RDF::RDFS.type, type)
    end

    def rdf_label
      get_values(self.class.rdf_label)
    end

    def set_value(property, values)
      values = [values] if values.kind_of? RDF::Graph
      values = Array(values)
      predicate = predicate_for_property(property)
      delete([rdf_subject, predicate, nil])
      values.each do |val|
        val = RDF::Literal(val) if val.kind_of? String
        #warn("Warning: #{val.to_s} is not of class #{property_class}.") unless val.kind_of? property_class or property_class == nil
        if val.kind_of? RdfResource
          add_child_node(property, val)
          next
        end
        val = val.to_uri if val.respond_to? :to_uri
        raise 'value must be an RDF URI, Node, Literal, or a plain string' unless
            val.kind_of? RDF::Resource or val.kind_of? RDF::Literal
        insert [rdf_subject, predicate, val]
      end
    end

    def get_values(property)
      values = []
      predicate = predicate_for_property(property)
      query(:subject => rdf_subject, :predicate => predicate).each_statement do |statement|
        value = statement.object
        value = value.to_s if value.kind_of? RDF::Literal
        value = make_node(property, value) if value.kind_of? RDF::Resource
        values << value
      end
      values
    end

    def set_subject!(uri_or_str)
      raise "Refusing update URI when one is already assigned!" unless rdf_subject.node?
      statements = query(:subject => rdf_subject)
      if uri_or_str.respond_to? :to_uri
        @rdf_subject = uri_or_str.to_uri
      elsif base_uri
        separator = self.base_uri.to_s[-1,1] =~ /(\/|#)/ ? '' : '/'
        @rdf_subject = RDF::URI.intern(self.base_uri.to_s + separator + uri_or_str.to_s)
      else
        @rdf_subject = RDF::URI(uri_or_str)
      end

      unless empty?
        statements.each_statement do |statement|
          delete(statement)
          self << RDF::Statement.new(rdf_subject, statement.predicate, statement.object)
        end
      end
    end

    def solrize
      return rdf_label unless rdf_label.empty?
      return rdf_subject.to_s unless node?
      return nil
    end

    private

    def predicate_for_property(property)
      return self.class.properties[property][:predicate] unless property.kind_of? RDF::URI
      return property
    end

    def property_for_predicate(predicate)
      self.class.properties.each do |property, values|
        return property if values[:predicate] == predicate
      end
      return nil
    end

    def class_for_property(property)
      klass = self.class.properties[property][:class_name] if self.class.properties.include? property
      klass ||= OregonDigital::RdfResource
      klass
    end

    def get_property_persistence(klass)
      repositories = {}
      klass.properties.each do |p, conf|
        repositories[conf[:predicate]] = conf[:persistence]
      end
      repositories
    end

    def add_child_node(property, resource)
      insert [rdf_subject, predicate_for_property(property), resource.rdf_subject]
      if self.class.properties[property][:persistence] == :parent
        self << resource
      else
        repos = get_property_persistence(resource.klass)
        resource.each_statement do |s|
          self << s if repos[s.predicate] == :parent
          RdfRepositories.repositories[repos[s.predicate]] << s
        end
      end
    end

    def make_node(property, value)
      klass = class_for_property(property)
      node = klass.new if value.node?
      node ||= klass.new(value)

      if node.node?
        query(:subject => value).each_statement do |s|
          s.subject = node.rdf_subject if s.subject == value
          node << s
        end
        return node
      end

      if self.class.properties[property][:persistence] == :parent
        default_repo = self
      else
        default_repo = RdfRepositories.repositories[self.class.properties[property][:persistence]]
      end
      node << default_repo.query(:subject => node.rdf_subject)


      repos = get_property_persistence(klass)
      repos.each do |pred, repo|
        next if repo == self.class.properties[property][:persistence]
        if repo == :parent
          repo = self
        else
          repo = RdfRepositories.repositories[repo]
        end
        next if repo.nil?
        node << repo.query(:subject => node.rdf_subject, :predicate => pred)
      end
      node
    end

  end
end
