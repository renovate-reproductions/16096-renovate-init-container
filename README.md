# renove test case

It demonstrate that renovate only updates the image for containers but not for init_containers.
This is only implemented at the moment for StateFullSets and is missing for the other resources.

Look here: https://github.com/renovatebot/renovate/blob/26a4d482a6834315cffedc2d46ecbeb7621bae62/lib/modules/manager/terraform/__fixtures__/kubernetes.tf
