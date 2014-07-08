require 'test_helper'

class ConfigInheritableTest < MiniTest::Spec
  class CloneableObject
    include Representable::Cloneable

    # same instance returns same clone.
    def clone
      @clone ||= super
    end
  end


  # InheritableArray
  it do
    parent = Representable::InheritableArray.new([1,2,3])
    child  = Representable::InheritableArray.new([4])

    child.inherit!(parent).must_equal([4,1,2,3])
  end

  # InheritableHash
  InheritableHash = Representable::InheritableHash
  describe "InheritableHash" do
    it do
      parent = InheritableHash[
        :volume => volume = Uber::Options::Value.new(9),
        :genre  => "Powermetal",
        :only_parent => only_parent = Representable::InheritableArray["Pumpkin Box"],
        :in_both     => in_both     = Representable::InheritableArray["Roxanne"],
        :hash => {:type => :parent},
        :clone => parent_clone = CloneableObject.new
      ]
      child  = InheritableHash[
        :genre => "Metal",
        :pitch => 99,
        :in_both => Representable::InheritableArray["Generator"],
        :hash => {:type => :child},
        :clone => child_clone = CloneableObject.new
      ]

      child.inherit!(parent)

      puts child.inspect

      child.size.must_equal 7

      # order:
      child.to_a.must_equal [
        [:genre, "Powermetal"], # parent overrides child
        [:pitch, 99],           # parent doesn't define pitch
        [:in_both, ["Generator", "Roxanne"]], # Inheritable array gets "merged".
        [:hash, {:type => :parent}], # normal hash merge: parent overwrites child value.
        [:clone, parent_clone.clone],
        [:volume, volume],
        [:only_parent, ["Pumpkin Box"]],
      ]

      # clone
      child[:only_parent].object_id.wont_equal parent[:only_parent].object_id
      child[:clone].object_id.wont_equal parent[:clone].object_id

      # still a hash:
      child.must_equal(
        :genre => "Powermetal",
        :pitch => 99,
        :in_both => ["Generator", "Roxanne"],
        :hash => {:type => :parent},
        :clone => parent_clone.clone,
        :volume => volume,
        :only_parent => ["Pumpkin Box"]
      )
    end

    # clone all elements when inheriting.
    it do
      parent = InheritableHash[:details => InheritableHash[:title => "Man Of Steel"]]
      child  = InheritableHash[].inherit!(parent)
      child[:details][:length] = 136

      parent.must_equal({:details => {:title => "Man Of Steel"}})
      child.must_equal( {:details => {:title => "Man Of Steel", :length => 136}})
    end
  end
end