
FactoryGirl.define do
  
  factory :a_tweet, class: ::Tweet do
    native_id "111"
    text "great news"
    coordinates [ -1.1, 3.1 ]
    user "u_handle_a"
  end

  factory :b_tweet, class: ::Tweet do
    native_id "222"
    text "There are probably red items in with my"
    coordinates [ -1.2, 3.1]
    user "u_handle_b"
  end
  
  factory :geo_disabled_tweet, class: ::Tweet do
    native_id "zzz"
    text "last last last"
    user "u_handle_b"
  end

end